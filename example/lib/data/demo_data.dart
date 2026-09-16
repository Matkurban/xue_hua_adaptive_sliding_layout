// 内存假数据，仅供 example 演示路由与栏位。

class MailThread {
  const MailThread({
    required this.id,
    required this.subject,
    required this.from,
    required this.body,
  });

  final String id;
  final String subject;
  final String from;
  final String body;
}

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.photoId,
  });

  final String id;
  final String name;
  final String email;
  final String photoId;
}

const mailFolders = <String, String>{
  'inbox': 'Inbox',
  'sent': 'Sent',
  'starred': 'Starred',
};

const mailThreads = <String, List<MailThread>>{
  'inbox': [
    MailThread(
      id: '1',
      subject: 'Welcome to sliding layout',
      from: 'Ada',
      body: 'PushNamed from a folder slides a thread into the right pane.',
    ),
    MailThread(
      id: '2',
      subject: 'Peer replace vs push',
      from: 'Linus',
      body: 'pushReplacementNamed swaps the right pane; pushNamed stacks it.',
    ),
    MailThread(
      id: '3',
      subject: 'Deep link friendly',
      from: 'Grace',
      body: 'The URL /mail/inbox/3 is the whole stack.',
    ),
  ],
  'sent': [
    MailThread(
      id: '10',
      subject: 'Re: calendar',
      from: 'You',
      body: 'Sent folder uses the same nested routes.',
    ),
  ],
  'starred': [
    MailThread(
      id: '20',
      subject: 'Keep-alive draft',
      from: 'You',
      body: 'Reply TextField state survives sliding off-screen.',
    ),
  ],
};

const contacts = <Contact>[
  Contact(id: '1', name: 'Ada Lovelace', email: 'ada@example.com', photoId: 'ada'),
  Contact(id: '2', name: 'Linus Torvalds', email: 'linus@example.com', photoId: 'linus'),
  Contact(id: '3', name: 'Grace Hopper', email: 'grace@example.com', photoId: 'grace'),
];

MailThread? threadById(String folder, String id) {
  final list = mailThreads[folder];
  if (list == null) return null;
  for (final thread in list) {
    if (thread.id == id) return thread;
  }
  return null;
}

Contact? contactById(String id) {
  for (final contact in contacts) {
    if (contact.id == id) return contact;
  }
  return null;
}
