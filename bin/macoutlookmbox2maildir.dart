import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http_utils/http_utils.dart';
import 'package:args/args.dart';

class Message {
  Message(String f) {
    this.from = f;
    contents = "";
  }
  String id;
  DateTime date;
  String contents;
  String from;

  bool isValidMessage() {
    if (from != null && date != null && from != null && contents != null) return true;
    return false;
  }
}

int errorCount = 0;
int messageCount = 0;

void main(List<String> args) {

  // parse results
  final parser = new ArgParser()..addFlag("write-changes", negatable: false, abbr: 'w', help: "actually perform changes");

  ArgResults argResults = parser.parse(args);
  List<String> paths = argResults.rest;
  if (paths.length == 0) {
    printHelp();
    return;
  }


  print("Roll out\n");

  Stream input;

  if (paths.length == 1) input = stdin; else input = new File(paths[0]).openRead();


  String inputText;
  Message msg;

  input.transform(LATIN1.decoder).transform(const LineSplitter()).listen((inputText) {

    if (inputText.toLowerCase().startsWith("from ") && inputText.contains("@")) {
      // save previous message
      if (msg != null) {
        SaveMessage(msg);
        messageCount++;
      }
      // make new message
      msg = new Message(inputText.substring(5));
    }

    if (msg != null) {

      if (inputText.toLowerCase().startsWith("date:")) {
        var parsedDate = ParseDate(inputText.substring(6));
        if (parsedDate != null) {
          msg.date = parsedDate;
        }
      }

      if (inputText.length > 12 && inputText.toLowerCase().startsWith("message-id:")) {
        msg.id = inputText.substring(12);
      }

      msg.contents += inputText + "\n";
    } else {
      print("skipping the stupid [${inputText}]");
    }
  }).onDone(() => stdout.writeln("Processed ${messageCount} messages.  Errors found on ${errorCount} "));

}

void printHelp() {
  print("macoutlook2mbox [-write-changes] [input files...] <output dir>");
  print("if no input files specified, then pipe from input");
}

void SaveMessage(Message msg) {
  if (msg.isValidMessage()) {
    stdout.writeln("message ${msg.id} from ${msg.from} written to ${msg.date.year.toString()}");
  } else {
    print("bad message!");
    errorCount++;
    print(msg.contents);
  }
}

DateTime ParseDate(String dateString) {
  try {
    return new DateUtils().parseRfc822Date(dateString);
  } on FormatException {
    try {
      return DateTime.parse(dateString);
    } on FormatException {
      return null;
    }
  }
}
