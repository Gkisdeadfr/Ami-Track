import '../models/exam.dart';
import '../models/syllabus.dart';
import '../models/assignment.dart';
import '../models/pyq.dart';

class InitialData {
  static List<ExamItem> get defaultExams => [
        // --- End Sem Practical Exams (CSE 3X) ---
        ExamItem(
          id: 'prac-ds-1',
          subjectCode: 'CSIT124',
          title: 'Data Structures Using C (External Practical)',
          date: DateTime(2026, 11, 17),
          time: '1:30 PM - 3:30 PM',
          type: ExamType.practical,
          labOrRoom: 'E1-1LA2',
          faculty: 'Dr. Seema Sharma',
          mode: 'External Practical [3CSE3-X]',
          syllabusSummary:
              'Linked Lists, Stacks, Queues, Binary Search Trees, Graph traversals (BFS/DFS), Sorting algorithms code execution and viva.',
        ),
        ExamItem(
          id: 'prac-deco-1',
          subjectCode: 'CSE207',
          title: 'Digital Electronics and Computer Org (Practical)',
          date: DateTime(2026, 11, 17),
          time: '1:30 PM - 3:30 PM',
          type: ExamType.practical,
          labOrRoom: 'E2-5LA4',
          faculty: 'Dr. Neha Arora',
          mode: 'External Practical [3CSE3-X]',
          syllabusSummary:
              'Logic gates, Multiplexers, Decoders, Adders/Subtractors circuit implementation, Breadboard/Simulator IC wiring & Viva.',
        ),
        ExamItem(
          id: 'prac-cpp-1',
          subjectCode: 'ES203',
          title: 'OOP Using C++ (External Practical)',
          date: DateTime(2026, 11, 26),
          time: '11:15 AM - 1:15 PM',
          type: ExamType.practical,
          labOrRoom: 'E3-3LA1',
          faculty: 'Dr. Seema Sharma',
          mode: 'External Practical [3CSE3-X]',
          syllabusSummary:
              'Classes & Objects, Operator Overloading, Inheritance, Virtual Functions, Polymorphism, File handling, STL & Viva.',
        ),
        ExamItem(
          id: 'prac-bee-1',
          subjectCode: 'ES201',
          title: 'Basic Electronics Engineering (Practical)',
          date: DateTime(2026, 11, 26),
          time: '1:30 PM - 3:30 PM',
          type: ExamType.practical,
          labOrRoom: 'E1-216',
          faculty: 'Prof. ANB',
          mode: 'External Practical [3CSE3-X]',
          syllabusSummary:
              'Diode V-I characteristics, Rectifiers, BJT CE configuration, Op-Amp inverting/non-inverting amplifiers & Viva.',
        ),
        ExamItem(
          id: 'prac-ml-1',
          subjectCode: 'AIML202',
          title: 'Machine Learning: Theory & App (Practical)',
          date: DateTime(2026, 11, 27),
          time: '1:30 PM - 3:30 PM',
          type: ExamType.practical,
          labOrRoom: 'E1-0LA2',
          faculty: 'Dr. Sumita Gupta',
          mode: 'External Practical [3CSE3-X]',
          syllabusSummary:
              'Python NumPy, Pandas, Scikit-Learn pipelines, Linear/Logistic Regression, Decision Trees, KNN, K-Means clustering implementation.',
        ),

        // --- End Sem Theory Exams (From Official Date Sheet) ---
        ExamItem(
          id: 'th-maths-1',
          subjectCode: 'MATH211',
          title: 'Applied Mathematics- III',
          date: DateTime(2026, 11, 16),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of Mathematics',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'Partial Differential Equations (PDE), Heat/Wave/Laplace Eqns, Fourier Series, Dirichlet conditions, Fourier Transforms.',
        ),
        ExamItem(
          id: 'th-cpp-1',
          subjectCode: 'ES203',
          title: 'Object Oriented Programming Using C++',
          date: DateTime(2026, 11, 20),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of CSE',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'OOP Principles, Constructors/Destructors, Friend Functions, Inheritance, Polymorphism, Virtual Base Classes, Templates, Exception Handling & STL.',
        ),
        ExamItem(
          id: 'th-grmn-1',
          subjectCode: 'GRMN142',
          title: 'Elementary German - II',
          date: DateTime(2026, 11, 21),
          time: '2:00 PM (14:00)',
          type: ExamType.theory,
          labOrRoom: 'Online / Exam Hall',
          faculty: 'Foreign Language Dept',
          mode: 'MCQ Regular [Sem - 3]',
          syllabusSummary:
              'German Grammar, Akkusativ & Dativ Prepositions, Modal verbs, Daily conversation dialogues, Reading comprehension & Vocabulary.',
        ),
        ExamItem(
          id: 'th-ds-1',
          subjectCode: 'CSIT124',
          title: 'Data Structures Using C',
          date: DateTime(2026, 11, 23),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of CSE',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'Arrays & Pointers, Stacks & Infix/Postfix/Tower of Hanoi, Queues, Linked Lists, Trees (BST, AVL, B-trees), Searching/Sorting, Graphs (BFS, DFS, Dijkstra, Prim/Kruskal).',
        ),
        ExamItem(
          id: 'th-ml-1',
          subjectCode: 'AIML202',
          title: 'Machine Learning: Theory and Applications',
          date: DateTime(2026, 11, 25),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of AI/ML',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'NumPy/Pandas/Scikit-learn, Bias-Variance tradeoff, Regression (Linear/Polynomial/Ridge/Lasso), Classification (Logistic, SVM, KNN, Naive Bayes), Decision Trees, Ensemble (Random Forest/Boosting), K-Means, PCA.',
        ),
        ExamItem(
          id: 'th-bee-1',
          subjectCode: 'ES201',
          title: 'Basic Electronics Engineering',
          date: DateTime(2026, 12, 2),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of ECE',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'Semiconductor Diodes & Applications, Rectifiers & Zener Regulators, BJT configurations & Biasing, JFET & MOSFET, Operational Amplifiers (Op-Amps 741), Basic Digital Gates.',
        ),
        ExamItem(
          id: 'th-deco-1',
          subjectCode: 'CSE207',
          title: 'Digital Electronics and Computer Organization',
          date: DateTime(2026, 12, 4),
          time: '10:00 AM',
          type: ExamType.theory,
          labOrRoom: 'Main Examination Hall',
          faculty: 'Dept of CSE',
          mode: 'Regular [Sem - 3]',
          syllabusSummary:
              'Combinational & Sequential Circuits, RTL & Micro-operations, Basic Computer Org (Instruction Cycle, Control Unit), CPU Architecture (Addressing Modes, RISC/CISC), Memory Hierarchy & Cache, Pipelining.',
        ),

        // --- Minor Exams (Reference / Archive) ---
        ExamItem(
          id: 'minor-maths-1',
          subjectCode: 'MATH211',
          title: 'Minor Exam: Applied Mathematics- III',
          date: DateTime(2026, 9, 25),
          time: '10:00 AM - 11:30 AM',
          type: ExamType.minor,
          labOrRoom: 'Classroom',
          faculty: 'Dept of Mathematics',
          mode: 'Minor Assessment',
          syllabusSummary: 'PDE First & Second order, Charpit method, Separation of variables.',
          isCompleted: true,
        ),
        ExamItem(
          id: 'minor-ds-1',
          subjectCode: 'CSIT124',
          title: 'Minor Exam: Data Structures Using C',
          date: DateTime(2026, 9, 27),
          time: '2:00 PM - 3:30 PM',
          type: ExamType.minor,
          labOrRoom: 'Classroom',
          faculty: 'Dept of CSE',
          mode: 'Minor Assessment',
          syllabusSummary: 'Arrays, Stacks, Queues, Singly & Doubly Linked Lists.',
          isCompleted: true,
        ),
      ];

  static List<SyllabusSubject> get defaultSyllabus => [
        // 1. Data Structures Using C (CSIT124)
        SyllabusSubject(
          id: 'sub-ds',
          subjectCode: 'CSIT124',
          subjectName: 'Data Structures Using C',
          colorHex: '#3B82F6',
          modules: [
            SyllabusModule(
              id: 'ds-m1',
              moduleTitle: 'Module I: Introduction to Data Structures',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ds-1-1', title: 'Definition, Types & Time-Space Tradeoffs', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-1-2', title: 'Pointers in Data Structures', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-1-3', title: 'Linear Arrays: Representation & Memory Addressing', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-1-4', title: 'Array Operations: Traversal, Insertion, Deletion', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-1-5', title: '2D & Multidimensional Arrays, Sparse Matrix', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'ds-m2',
              moduleTitle: 'Module II: Stacks and Queues',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ds-2-1', title: 'Stack Array Representation & Push/Pop', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-2-2', title: 'Infix to Postfix & Prefix Conversion', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-2-3', title: 'Stack Applications & Tower of Hanoi', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-2-4', title: 'Linear Queues: Insert, Delete, Underflow/Overflow', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-2-5', title: 'Circular Queues, Priority Queues, Deque', status: TopicStatus.inProgress),
              ],
            ),
            SyllabusModule(
              id: 'ds-m3',
              moduleTitle: 'Module III: Programming with Linked Lists',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'ds-3-1', title: 'Singly Linked Lists: Node creation & Traversal', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-3-2', title: 'Insertion & Deletion at Head, Middle, End', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-3-3', title: 'Doubly Linked Lists & Operations', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-3-4', title: 'Circular Linked Lists & Applications', status: TopicStatus.notStarted),
                SyllabusTopic(id: 'ds-3-5', title: 'Polynomial Representation using Linked Lists', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-3-6', title: 'Stack & Queue Implementation via Linked List', status: TopicStatus.done),
              ],
            ),
            SyllabusModule(
              id: 'ds-m4',
              moduleTitle: 'Module IV: Trees and Applications',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'ds-4-1', title: 'Basic Terminology: Height, Depth, Degree', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-4-2', title: 'Binary Tree Traversals (Inorder, Preorder, Postorder)', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-4-3', title: 'Binary Search Tree (BST): Insert, Delete, Search', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-4-4', title: 'AVL Trees & Rotations (LL, RR, LR, RL)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-4-5', title: 'Threaded Binary Trees & B-Trees Introduction', status: TopicStatus.notStarted),
              ],
            ),
            SyllabusModule(
              id: 'ds-m5',
              moduleTitle: 'Module V: Searching and Sorting Techniques',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ds-5-1', title: 'Linear Search & Binary Search (Iterative & Recursive)', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-5-2', title: 'Bubble, Selection & Insertion Sort', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-5-3', title: 'Quick Sort (Partition logic & Complexity)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-5-4', title: 'Merge Sort & Heap Sort', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-5-5', title: 'Hashing: Hash Functions & Collision Resolution', status: TopicStatus.inProgress),
              ],
            ),
            SyllabusModule(
              id: 'ds-m6',
              moduleTitle: 'Module VI: Graph and Their Applications',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ds-6-1', title: 'Graph Terminology & Representation (Matrix & Adjacency List)', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-6-2', title: 'Graph Traversals: Breadth First Search (BFS)', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-6-3', title: 'Graph Traversals: Depth First Search (DFS)', status: TopicStatus.done),
                SyllabusTopic(id: 'ds-6-4', title: 'Minimum Spanning Trees: Prim\'s Algorithm', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-6-5', title: 'Minimum Spanning Trees: Kruskal\'s Algorithm', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ds-6-6', title: 'Warshall\'s & Shortest Path Algorithms', status: TopicStatus.notStarted),
              ],
            ),
          ],
        ),

        // 2. Object Oriented Programming Using C++ (ES203)
        SyllabusSubject(
          id: 'sub-cpp',
          subjectCode: 'ES203',
          subjectName: 'OOP Using C++',
          colorHex: '#8B5CF6',
          modules: [
            SyllabusModule(
              id: 'cpp-m1',
              moduleTitle: 'Module 1: Introduction to OOP',
              weightage: 10.0,
              topics: [
                SyllabusTopic(id: 'cpp-1-1', title: 'Difference between C and C++', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-1-2', title: 'OOP Principles: Abstraction & Encapsulation', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-1-3', title: 'Inheritance, Polymorphism & Dynamic Binding', status: TopicStatus.done),
              ],
            ),
            SyllabusModule(
              id: 'cpp-m2',
              moduleTitle: 'Module II: Classes & Objects',
              weightage: 25.0,
              topics: [
                SyllabusTopic(id: 'cpp-2-1', title: 'Classes, Objects, Attributes & Methods', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-2-2', title: 'Scope Resolution Operator (::)', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-2-3', title: 'Friend Functions & Inline Functions', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'cpp-2-4', title: 'Constructors: Default, Parameterized, Copy', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-2-5', title: 'Destructors & Dynamic Memory (new/delete)', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-2-6', title: 'Static Class Members & Array of Objects', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'cpp-m3',
              moduleTitle: 'Module III: Inheritance',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'cpp-3-1', title: 'Inheritance Types (Single, Multiple, Multilevel, Hierarchical, Hybrid)', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-3-2', title: 'Access Modes: Public, Private, Protected', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-3-3', title: 'Ambiguity Resolution & Virtual Base Class', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'cpp-3-4', title: 'Constructors in Derived Classes & Nesting', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'cpp-m4',
              moduleTitle: 'Module IV: Polymorphism',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'cpp-4-1', title: 'Compile-time vs Run-time Polymorphism', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-4-2', title: 'Function Overloading', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-4-3', title: 'Operator Overloading (Unary & Binary ++, +, <<)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'cpp-4-4', title: 'Pointers to Objects & "this" Pointer', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-4-5', title: 'Virtual Functions & Pure Virtual Functions (Abstract Class)', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'cpp-m5',
              moduleTitle: 'Module V: Strings, Files & Exception Handling & STL',
              weightage: 25.0,
              topics: [
                SyllabusTopic(id: 'cpp-5-1', title: 'Streams and File Handling (ifstream, ofstream, fstream)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'cpp-5-2', title: 'Formatted and Unformatted I/O', status: TopicStatus.done),
                SyllabusTopic(id: 'cpp-5-3', title: 'Exception Handling (try, catch, throw)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'cpp-5-4', title: 'Templates: Function Templates & Class Templates', status: TopicStatus.inProgress),
                SyllabusTopic(id: 'cpp-5-5', title: 'Standard Template Library (STL): Vectors, Iterators, Algorithms', status: TopicStatus.needsRevision),
              ],
            ),
          ],
        ),

        // 3. Machine Learning: Theory and Applications (AIML202)
        SyllabusSubject(
          id: 'sub-ml',
          subjectCode: 'AIML202',
          subjectName: 'Machine Learning',
          colorHex: '#10B981',
          modules: [
            SyllabusModule(
              id: 'ml-m1',
              moduleTitle: 'Module I: Python for Machine Learning',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ml-1-1', title: 'NumPy Operations & Vectorized Computations', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-1-2', title: 'Data Handling with Pandas: Filter, Group, Merge', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-1-3', title: 'Data Cleaning: Missing Values & Outliers', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-1-4', title: 'Matplotlib & Seaborn Visualization', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-1-5', title: 'Scikit-learn Workflow & Preprocessing Pipelines', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'ml-m2',
              moduleTitle: 'Module II: Foundation of ML & Data Prep',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'ml-2-1', title: 'Supervised vs Unsupervised vs Reinforcement Learning', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-2-2', title: 'Feature Scaling: Normalization & Standardization', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-2-3', title: 'Model Complexity: Overfitting vs Underfitting', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-2-4', title: 'Cross-Validation & Train/Test Splitting', status: TopicStatus.done),
              ],
            ),
            SyllabusModule(
              id: 'ml-m3',
              moduleTitle: 'Module III: Supervised Learning (Regression & Classification)',
              weightage: 30.0,
              topics: [
                SyllabusTopic(id: 'ml-3-1', title: 'Linear Regression & Cost Function (MSE)', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-3-2', title: 'Regularization: Ridge, Lasso & Elastic Net', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-3-3', title: 'Bias-Variance Tradeoff', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-3-4', title: 'Logistic Regression & Sigmoid Curve', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-3-5', title: 'Support Vector Machines (Hard/Soft Margin, Kernel Trick)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-3-6', title: 'Naive Bayes Classifier & Bayes Theorem', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-3-7', title: 'K-Nearest Neighbours (KNN) & Distance Metrics', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-3-8', title: 'Evaluation: Confusion Matrix, Precision, Recall, F1, ROC-AUC', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'ml-m4',
              moduleTitle: 'Module IV: Decision Trees and Ensemble Learning',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'ml-4-1', title: 'Decision Trees: Information Gain & Gini Index', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-4-2', title: 'Tree Pruning & Overfitting Mitigation', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-4-3', title: 'Bagging & Random Forest Classifier', status: TopicStatus.inProgress),
                SyllabusTopic(id: 'ml-4-4', title: 'Boosting: Gradient Boosting & AdaBoost', status: TopicStatus.notStarted),
              ],
            ),
            SyllabusModule(
              id: 'ml-m5',
              moduleTitle: 'Module V: Unsupervised Learning & Dimensionality Reduction',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'ml-5-1', title: 'K-Means Clustering & Elbow Method', status: TopicStatus.done),
                SyllabusTopic(id: 'ml-5-2', title: 'Hierarchical Clustering & Dendrograms', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ml-5-3', title: 'Silhouette Score & Davies-Bouldin Index', status: TopicStatus.notStarted),
                SyllabusTopic(id: 'ml-5-4', title: 'Principal Component Analysis (PCA)', status: TopicStatus.needsRevision),
              ],
            ),
          ],
        ),

        // 4. Digital Electronics and Computer Organization (CSE207)
        SyllabusSubject(
          id: 'sub-deco',
          subjectCode: 'CSE207',
          subjectName: 'Digital Electronics & Computer Org',
          colorHex: '#F59E0B',
          modules: [
            SyllabusModule(
              id: 'deco-m1',
              moduleTitle: 'Module 1: Digital Electronics',
              weightage: 25.0,
              topics: [
                SyllabusTopic(id: 'deco-1-1', title: 'Multiplexers, Demultiplexers, Encoders, Decoders', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-1-2', title: 'Adders, Subtractors and ALU Design', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-1-3', title: 'Register Transfer & Bus Architecture', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-1-4', title: 'Arithmetic, Logic & Shift Micro-operations', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'deco-m2',
              moduleTitle: 'Module 2: Basic Computer Organization & Design',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'deco-2-1', title: 'Instruction Codes & Computer Registers', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-2-2', title: 'Instruction Cycle: Fetch, Decode, Execute', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-2-3', title: 'Input-Output & Interrupt Cycle', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-2-4', title: 'Hardwired vs Microprogrammed Control Unit', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'deco-m3',
              moduleTitle: 'Module 3: Central Processing Unit (CPU)',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'deco-3-1', title: 'General Register Organization & Stack Org', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-3-2', title: 'Instruction Formats & Addressing Modes', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-3-3', title: 'RISC vs CISC Architecture', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-3-4', title: 'Multiplication & Division Algorithms (Booth\'s Algorithm)', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'deco-m4',
              moduleTitle: 'Module 4: Memory Organization',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'deco-4-1', title: 'Memory Hierarchy, RAM & ROM Chips', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-4-2', title: 'Cache Memory Mapping (Direct, Associative, Set-Associative)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-4-3', title: 'Virtual Memory & Page Replacement', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-4-4', title: 'I/O Bus & Asynchronous Data Transfer', status: TopicStatus.inProgress),
              ],
            ),
            SyllabusModule(
              id: 'deco-m5',
              moduleTitle: 'Module 5: Pipelining & Multiprocessors',
              weightage: 15.0,
              topics: [
                SyllabusTopic(id: 'deco-5-1', title: 'Parallel Processing & Pipelining Fundamentals', status: TopicStatus.done),
                SyllabusTopic(id: 'deco-5-2', title: 'Arithmetic Pipeline & Instruction Pipeline', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-5-3', title: 'Pipeline Hazards (Structural, Data, Control)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'deco-5-4', title: 'Multiprocessors & Interconnection Structures', status: TopicStatus.notStarted),
              ],
            ),
          ],
        ),

        // 5. Applied Mathematics- III (MATH211)
        SyllabusSubject(
          id: 'sub-maths',
          subjectCode: 'MATH211',
          subjectName: 'Applied Mathematics- III',
          colorHex: '#EF4444',
          modules: [
            SyllabusModule(
              id: 'math-m1',
              moduleTitle: 'Module 1: Partial Differential Equations',
              weightage: 25.0,
              topics: [
                SyllabusTopic(id: 'math-1-1', title: 'Formation of PDE by eliminating constants/functions', status: TopicStatus.done),
                SyllabusTopic(id: 'math-1-2', title: 'First Order Linear PDE (Lagrange\'s Method)', status: TopicStatus.done),
                SyllabusTopic(id: 'math-1-3', title: 'Non-linear First Order PDE & Charpit\'s Method', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-1-4', title: 'Homogeneous & Non-homogeneous Linear PDE with constant coefficients', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'math-m2',
              moduleTitle: 'Module 2: Applications of Partial Differential Equations',
              weightage: 25.0,
              topics: [
                SyllabusTopic(id: 'math-2-1', title: 'Method of Separation of Variables', status: TopicStatus.done),
                SyllabusTopic(id: 'math-2-2', title: 'One Dimensional Wave Equation (Vibrating String)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-2-3', title: 'One Dimensional Heat Conduction Equation', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-2-4', title: 'Two Dimensional Laplace Equation', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-2-5', title: 'Classification into Elliptic, Parabolic & Hyperbolic forms', status: TopicStatus.done),
              ],
            ),
            SyllabusModule(
              id: 'math-m3',
              moduleTitle: 'Module 3: Fourier Series',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'math-3-1', title: 'Periodic Functions & Dirichlet\'s Conditions', status: TopicStatus.done),
                SyllabusTopic(id: 'math-3-2', title: 'Fourier Series for Even and Odd Functions', status: TopicStatus.done),
                SyllabusTopic(id: 'math-3-3', title: 'Change of Interval & Half Range Sine/Cosine Series', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-3-4', title: 'Harmonic Analysis & Parseval\'s Identity', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'math-m4',
              moduleTitle: 'Module 4: Fourier Transforms',
              weightage: 30.0,
              topics: [
                SyllabusTopic(id: 'math-4-1', title: 'Fourier Integral Theorem', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-4-2', title: 'Fourier Sine and Cosine Integrals', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-4-3', title: 'Complex Fourier Transform & Properties', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'math-4-4', title: 'Inverse Fourier Transform & Convolution Theorem', status: TopicStatus.notStarted),
              ],
            ),
          ],
        ),

        // 6. Basic Electronics Engineering (ES201)
        SyllabusSubject(
          id: 'sub-bee',
          subjectCode: 'ES201',
          subjectName: 'Basic Electronics Engineering',
          colorHex: '#06B6D4',
          modules: [
            SyllabusModule(
              id: 'bee-m1',
              moduleTitle: 'Module I: Semiconductor Diode & Circuits',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'bee-1-1', title: 'P-N Junction, Diffusion & Drift Current', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-1-2', title: 'Diode Resistance & Load Line Analysis', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-1-3', title: 'Zener Diode as Voltage Regulator', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'bee-1-4', title: 'Half Wave & Full Wave Rectifiers (Center tap & Bridge)', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-1-5', title: 'Clipping and Clamping Circuits', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'bee-m2',
              moduleTitle: 'Module II: Bipolar Junction Transistor (BJT)',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'bee-2-1', title: 'BJT Construction & Operation (CB, CE, CC)', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-2-2', title: 'CE Input/Output Characteristics & Q-Point', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-2-3', title: 'Transistor Biasing & Stability Factor', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'bee-2-4', title: 'RC Coupled Amplifier Frequency Response', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'bee-m3',
              moduleTitle: 'Module III: Field Effect Transistors (FET)',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'bee-3-1', title: 'JFET Operation, V-I Characteristics & Pinch-off', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-3-2', title: 'MOSFET: Depletion and Enhancement Mode', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'bee-3-3', title: 'Common Source Amplifier & Source Follower', status: TopicStatus.notStarted),
              ],
            ),
            SyllabusModule(
              id: 'bee-m4',
              moduleTitle: 'Module IV: Operational Amplifiers (Op-Amps)',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'bee-4-1', title: 'Differential Amplifier & CMRR Concept', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-4-2', title: '741 Op-Amp Pin Config & Ideal Characteristics', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-4-3', title: 'Concept of Virtual Ground & Slew Rate', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'bee-4-4', title: 'Inverting & Non-inverting Op-Amp Amplifiers', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-4-5', title: 'Op-Amp Adder, Subtractor & Comparator', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'bee-m5',
              moduleTitle: 'Module V: Basic Digital Electronics',
              weightage: 20.0,
              topics: [
                SyllabusTopic(id: 'bee-5-1', title: 'Logic Gates (AND, OR, NOT, NAND, NOR, XOR)', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-5-2', title: 'Boolean Algebra Laws & De Morgan\'s Theorems', status: TopicStatus.done),
                SyllabusTopic(id: 'bee-5-3', title: 'Flip-Flops (SR, JK, D, T) & Truth Tables', status: TopicStatus.needsRevision),
              ],
            ),
          ],
        ),

        // 7. Elementary German - II (GRMN142)
        SyllabusSubject(
          id: 'sub-german',
          subjectCode: 'GRMN142',
          subjectName: 'Elementary German - II',
          colorHex: '#14B8A6',
          modules: [
            SyllabusModule(
              id: 'grmn-m1',
              moduleTitle: 'Grammar and Cases',
              weightage: 40.0,
              topics: [
                SyllabusTopic(id: 'ger-1', title: 'Nominativ, Akkusativ & Dativ Personalpronomen', status: TopicStatus.done),
                SyllabusTopic(id: 'ger-2', title: 'Wechselpräpositionen (Dual prepositions)', status: TopicStatus.needsRevision),
                SyllabusTopic(id: 'ger-3', title: 'Modalverben im Präsens (können, müssen, wollen)', status: TopicStatus.done),
                SyllabusTopic(id: 'ger-4', title: 'Perfekt Tense with haben & sein', status: TopicStatus.needsRevision),
              ],
            ),
            SyllabusModule(
              id: 'grmn-m2',
              moduleTitle: 'Vocabulary & Conversational Situations',
              weightage: 60.0,
              topics: [
                SyllabusTopic(id: 'ger-5', title: 'Wegbeschreibung (Directions) & Orientierung', status: TopicStatus.done),
                SyllabusTopic(id: 'ger-6', title: 'Einkaufen & Kleidung (Shopping & Clothing)', status: TopicStatus.done),
                SyllabusTopic(id: 'ger-7', title: 'Im Restaurant bestellen (Ordering in Restaurant)', status: TopicStatus.done),
                SyllabusTopic(id: 'ger-8', title: 'Tagesablauf & Freizeitaktivitäten (Daily routines)', status: TopicStatus.needsRevision),
              ],
            ),
          ],
        ),
      ];

  static List<Assignment> get defaultAssignments => [
        Assignment(
          id: 'asg-1',
          title: 'Implement AVL Tree Rotations & Deletion in C',
          subject: 'CSIT124 - Data Structures',
          submissionDate: DateTime(2026, 11, 14),
          status: AssignmentStatus.ongoing,
          notes: 'Cover LL, RR, LR, RL rotations and test with random inputs.',
        ),
        Assignment(
          id: 'asg-2',
          title: 'Design 4-Bit ALU in Logisim / Simulator',
          subject: 'CSE207 - DECO',
          submissionDate: DateTime(2026, 11, 15),
          status: AssignmentStatus.completed,
          notes: 'Completed circuits for ADD, SUB, AND, OR. Need to print report.',
        ),
        Assignment(
          id: 'asg-3',
          title: 'Classification Comparison: SVM vs Random Forest on Titanic Dataset',
          subject: 'AIML202 - Machine Learning',
          submissionDate: DateTime(2026, 11, 18),
          status: AssignmentStatus.todo,
          notes: 'Include confusion matrix, F1-score and ROC curve plots.',
        ),
        Assignment(
          id: 'asg-4',
          title: 'Template Class for Dynamic Array & Stack in C++',
          subject: 'ES203 - OOP Using C++',
          submissionDate: DateTime(2026, 11, 10),
          status: AssignmentStatus.submitted,
          notes: 'Submitted on college portal.',
        ),
        Assignment(
          id: 'asg-5',
          title: 'BEE Lab File: Op-Amp Inverting & Non-Inverting Characteristics',
          subject: 'ES201 - BEE',
          submissionDate: DateTime(2026, 11, 19),
          status: AssignmentStatus.todo,
          notes: 'Write practical observations and calculate gain.',
        ),
      ];

  static List<PYQItem> get defaultPYQs => [
        PYQItem(
          id: 'pyq-ds-2025',
          title: 'Data Structures Using C - End Sem Question Paper',
          subject: 'Data Structures Using C',
          subjectCode: 'CSIT124',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '1.4 MB',
          pageCount: 3,
          questionsPreview: [
            'Q1. Construct an AVL tree by inserting elements: 65, 34, 12, 80, 92, 10, 45, 23. Show all rotations.',
            'Q2. Write a C program to implement Breadth First Search (BFS) using Queue.',
            'Q3. Explain Dijkstra\'s Single Source Shortest Path Algorithm with time complexity analysis.',
            'Q4. Differentiate between Singly Linked List and Doubly Linked List with memory overhead.',
          ],
        ),
        PYQItem(
          id: 'pyq-deco-2025',
          title: 'Digital Electronics & Computer Org - End Sem Question Paper',
          subject: 'Digital Electronics & Computer Org',
          subjectCode: 'CSE207',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '1.8 MB',
          pageCount: 4,
          questionsPreview: [
            'Q1. Draw and explain the common bus system using multiplexers for 4 registers of 4 bits each.',
            'Q2. Explain Booth\'s Multiplication Algorithm with a flow chart and multiply (-5) x (+7).',
            'Q3. Discuss Direct, Associative and Set-Associative Cache Mapping with diagrams.',
            'Q4. What are pipeline hazards? Explain data dependency and branch hazards with solutions.',
          ],
        ),
        PYQItem(
          id: 'pyq-ml-2025',
          title: 'Machine Learning: Theory & Applications - End Sem Paper',
          subject: 'Machine Learning',
          subjectCode: 'AIML202',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '2.1 MB',
          pageCount: 4,
          questionsPreview: [
            'Q1. Explain the Bias-Variance tradeoff with diagram. How do Ridge and Lasso regressions address overfitting?',
            'Q2. Calculate Information Gain and Gini Index for a given weather dataset for Decision Tree split.',
            'Q3. Derive the dual formulation of Support Vector Machines (SVM) with soft margin slack variable.',
            'Q4. Step-by-step algorithm of K-Means clustering. How to choose optimal K using Elbow method?',
          ],
        ),
        PYQItem(
          id: 'pyq-cpp-2025',
          title: 'Object Oriented Programming Using C++ - End Sem Paper',
          subject: 'OOP Using C++',
          subjectCode: 'ES203',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '1.2 MB',
          pageCount: 3,
          questionsPreview: [
            'Q1. Explain Diamond problem in multiple inheritance. How does virtual base class resolve ambiguity?',
            'Q2. Write a C++ program to overload \'+\' operator for adding two complex number objects.',
            'Q3. Explain virtual functions and runtime polymorphism with vtable and vptr mechanism.',
            'Q4. Write a program using C++ STL Vector and Algorithm sort to find top 5 scores.',
          ],
        ),
        PYQItem(
          id: 'pyq-math-2025',
          title: 'Applied Mathematics- III - End Sem Question Paper',
          subject: 'Applied Mathematics- III',
          subjectCode: 'MATH211',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '1.6 MB',
          pageCount: 3,
          questionsPreview: [
            'Q1. Solve the one-dimensional wave equation u_tt = c^2 u_xx subject to boundary conditions.',
            'Q2. Find the Fourier series expansion of f(x) = x^2 in the interval (-pi, pi). Hence deduce Parseval sum.',
            'Q3. Solve by Charpit\'s method: (p^2 + q^2)y = qz.',
            'Q4. Find the Fourier transform of f(x) = e^(-a|x|) where a > 0.',
          ],
        ),
        PYQItem(
          id: 'pyq-bee-2025',
          title: 'Basic Electronics Engineering - End Sem Paper',
          subject: 'Basic Electronics Engineering',
          subjectCode: 'ES201',
          examType: 'End Sem Exam',
          year: '2025-26',
          fileSize: '1.5 MB',
          pageCount: 3,
          questionsPreview: [
            'Q1. Explain the working of a Full Wave Bridge Rectifier with input/output waveforms and ripple factor formula.',
            'Q2. Draw the circuit diagram of Op-Amp as Inverting and Non-inverting amplifier and derive voltage gain.',
            'Q3. Explain CE Transistor output characteristics in Active, Saturation and Cutoff regions.',
            'Q4. Realize Full Adder circuit using only NAND gates.',
          ],
        ),
      ];
}
