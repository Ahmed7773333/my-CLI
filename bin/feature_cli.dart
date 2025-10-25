#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'create feature command.dart';
import 'generate hive command.dart';

void main(List<String> args) {
  final parser = ArgParser();
  parser.addCommand('create');
  parser.addCommand('generate');

  final ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('Error: ${e.toString()}');
    printUsage(parser);
    exit(1);
  }

  // CREATE FEATURE command
  if (results.command?.name == 'create') {
    runCreateFeature(results.command!.rest);
    return;
  }

  // GENERATE commands
  if (results.command?.name == 'generate') {
    runGenerateHive(results.command!.rest);
    return;
  }

  // default help
  printUsage(parser);
  exit(0);
}

void printUsage(ArgParser parser) {
  print('Usage:');
  print('  feature_cli create feature <feature_name>');
  print('  feature_cli generate hive <path/to/model.dart>');
}
