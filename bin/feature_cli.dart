#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'create feature command.dart';
import 'generate hive command.dart';
import 'create clean arch project.dart';

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

  final command = results.command;
  if (command == null) {
    printUsage(parser);
    exit(0);
  }

  final commandName = command.name;
  final rest = command.rest;

  if (commandName == 'create') {
    if (rest.isEmpty) {
      print('Error: Missing subcommand for "create".');
      printUsage(parser);
      exit(1);
    }

    final subCommand = rest[0];
    if (subCommand == 'feature') {
      // Pass the *full* rest list, as the original function expects it
      runCreateFeature(rest);
    } else if (subCommand == 'project') {
      // Pass the *full* rest list, my new function will parse it
      runCreateProject(rest);
    } else {
      print('Error: Unknown subcommand "$subCommand" for "create".');
      printUsage(parser);
      exit(1);
    }
    return;
  }

  if (commandName == 'generate') {
    // The original runGenerateHive handles subcommands itself
    runGenerateHive(rest);
    return;
  }

  // default help
  printUsage(parser);
  exit(0);
}

void printUsage(ArgParser parser) {
  print('Usage: feature_cli <command> <subcommand> [options]');
  print('');
  print('Available commands:');
  print('  create');
  print('    feature <feature_name>    - Creates a new feature module.');
  print('    project <project_name>    - Creates a new full Flutter project.');
  print('');
  print('  generate');
  print(
      '    hive <path/to/model.dart> - Generates Hive adapter and helper files.');
  print('');
}
