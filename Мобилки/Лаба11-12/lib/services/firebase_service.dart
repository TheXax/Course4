import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService() {
    try { //локальное хранение данных; чтение данных без интернета
      _firestore.settings = const Settings(persistenceEnabled: true);
    } catch (_) {
    }
  }

  CollectionReference collection(String name) => _firestore.collection(name);

  Future<DocumentReference> addDocument(String collectionName, Map<String, dynamic> data) async {
    return await collection(collectionName).add(data);
  }

  Future<void> setDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    await collection(collectionName).doc(docId).set(data);
  }

  Future<void> updateDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    await collection(collectionName).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collectionName, String docId) async {
    await collection(collectionName).doc(docId).delete();
  }

  Stream<QuerySnapshot> collectionStream(String collectionName) {
    return collection(collectionName).snapshots();
  }

  Future<DocumentSnapshot> getDocument(String collectionName, String docId) async {
    return await collection(collectionName).doc(docId).get();
  }
}
