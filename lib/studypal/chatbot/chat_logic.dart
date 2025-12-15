import 'dart:math';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatLogic {
  final Gemini gemini = Gemini.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Retry helper for handling network issues and rate limiting
  Future<T?> _withRetry<T>(Future<T?> Function() fn, {int retries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        final msg = e.toString();
        // If rate limit (429) is hit, wait and retry
        if (attempt <= retries && msg.contains('429')) {
          final wait = Duration(seconds: 1 << (attempt - 1));
          print('Rate limited. Retrying in ${wait.inSeconds} seconds...');
          await Future.delayed(wait);
          continue;
        }
        rethrow;
      }
    }
  }

  // Get AI response to user question with semantic search in notes (RAG)
  Future<String> getAnswer(String userQuestion) async {
    // Validation: Do not make API call if question is empty
    if (userQuestion.trim().isEmpty) {
      return "Please enter a valid question.";
    }

    try {
      // Step 1: Get embedding of user question using text-embedding-004 model
      final rawResult = await _withRetry(
        () =>
            gemini.embedContent(userQuestion, modelName: 'text-embedding-004'),
      );

      List<double> queryVector = [];

      // Safe type casting from response
      if (rawResult != null) {
        // Check if response is a list
        if (rawResult is List) {
          queryVector = rawResult.map((e) => (e as num).toDouble()).toList();
        } else {
          return "Error: Internal AI format mismatch.";
        }
      } else {
        return "Sorry, I couldn't understand the question (embedding failed).";
      }

      // Step 2: Fetch saved notes from Firebase
      QuerySnapshot snapshot = await firestore.collection('notes').get();

      List<Map<String, dynamic>> scoredNotes = [];

      // Step 3: Score each note based on semantic similarity
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['vector'] != null) {
          List<double> noteVector = (data['vector'] as List)
              .map((e) => (e as num).toDouble())
              .toList();

          double score = _calculateSimilarity(queryVector, noteVector);

          // Keep notes above similarity threshold of 0.60
          if (score > 0.60) {
            scoredNotes.add({'content': data['content'], 'score': score});
          }
        }
      }

      // Step 4: Get top 3 matching notes
      scoredNotes.sort((a, b) => b['score'].compareTo(a['score']));
      var topMatches = scoredNotes.take(3).toList();

      String contextString = "";
      if (topMatches.isNotEmpty) {
        contextString = "Relevant information from your notes:\n";
        for (var note in topMatches) {
          contextString += "- ${note['content']}\n";
        }
      }

      // Step 5: Build prompt with context for AI response
      String fullPrompt =
          "You are 'StudyPal', a helpful classroom assistant.\n"
          "Answer the user's question using the notes provided below. "
          "If the answer isn't in the notes, say 'I couldn't find this in your notes' and then try to answer from general knowledge.\n\n"
          "$contextString\n"
          "User Question: $userQuestion\n"
          "Answer:";

      final response = await _withRetry(
        () => gemini.prompt(parts: [Part.text(fullPrompt)]),
      );
      return response?.output ?? "Sorry, no response from AI.";
    } catch (e) {
      print("Error in getAnswer: $e");
      // Show exact error to help with debugging
      return "Error: Something went wrong. Details: $e";
    }
  }

  // Save note to Firestore with semantic embedding for future retrieval
  Future<void> saveNoteToMemory(String title, String content) async {
    // Validation: Do not save empty notes
    if (content.trim().isEmpty) return;

    try {
      // Generate embedding for the note using text-embedding-004 model
      final rawEmbedding = await _withRetry(
        () => gemini.embedContent(content, modelName: 'text-embedding-004'),
      );

      if (rawEmbedding != null) {
        // Safe type casting
        List<double> embedding = [];
        if (rawEmbedding is List) {
          embedding = rawEmbedding.map((e) => (e as num).toDouble()).toList();
        }

        if (embedding.isNotEmpty) {
          await firestore.collection('notes').add({
            'title': title,
            'content': content,
            'vector': embedding,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print("Error saving note: $e");
      throw e;
    }
  }

  // Calculate cosine similarity between two embedding vectors
  double _calculateSimilarity(List<double> vecA, List<double> vecB) {
    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    // Use the smaller length to avoid index out of bounds
    int length = min(vecA.length, vecB.length);

    for (int i = 0; i < length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
