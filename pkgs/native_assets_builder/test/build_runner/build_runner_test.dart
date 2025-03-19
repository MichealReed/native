// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('native_add build', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('simple_data_asset/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      // Trigger a build, should invoke build for libraries with native assets.
      {
        final logMessages = <String>[];
        final result =
            (await build(
              packageUri,
              logger,
              dartExecutable,
              capturedLogs: logMessages,
              buildAssetTypes: [CodeAsset.type],
            ))!;
        expect(
          logMessages.join('\n'),
          stringContainsInOrder([
            'native_add${Platform.pathSeparator}hook'
                '${Platform.pathSeparator}build.dart',
          ]),
        );
        expect(result.encodedAssets.length, 1);

        // Check that invocation logs are written to disk.
        final packgeBuildDirectory = Directory.fromUri(
          packageUri.resolve('.dart_tool/native_assets_builder/native_add/'),
        );
        final buildDirectory =
            packgeBuildDirectory.listSync().single as Directory;
        final stdoutFile = File.fromUri(
          buildDirectory.uri.resolve('stdout.txt'),
        );
        final stderrFile = File.fromUri(
          buildDirectory.uri.resolve('stderr.txt'),
        );
        expect(stdoutFile.existsSync(), true);
        expect(
          stdoutFile.readAsStringSync(encoding: systemEncoding),
          contains('Some stdout.'),
        );
        expect(stderrFile.existsSync(), true);
        expect(
          stderrFile.readAsStringSync(encoding: systemEncoding),
          contains('Some stderr.'),
        );
      }

      // Trigger a build, should not invoke anything.
      final logMessages = <String>[];
      final result =
          (await build(
            packageUri,
            logger,
            dartExecutable,
            capturedLogs: logMessages,
            buildAssetTypes: [CodeAsset.type],
          ))!;
      expect(
        false,
        logMessages
            .join('\n')
            .contains(
              'native_add${Platform.pathSeparator}hook'
              '${Platform.pathSeparator}build.dart',
            ),
      );
      expect(result.encodedAssets.length, 1);
    });
  });
}
