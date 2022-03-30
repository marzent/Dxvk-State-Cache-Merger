//
//  main.swift
//  DxvkStateCacheMerger
//
//  Created by Marc-Aurel Zent on 30.03.22.
//

import Foundation


guard CommandLine.arguments.count > 2 else {
    print("Usage: dxvk-state-cache-merger inputCacheFile1 ... inputCacheFileN mergedCacheFile")
    exit(-1)
}

let inputFiles = Array(CommandLine.arguments.dropFirst().dropLast())
let outFile = CommandLine.arguments.last!

func parse(filePaths: [String]) -> [DxvkStateCache] {
    do {
        let inputData = try filePaths.map {try Data(contentsOf: URL(fileURLWithPath: $0))}
        return try inputData.map {try DxvkStateCache(inputData: $0)}
    } catch {
        print(error)
        exit(-1)
    }
}

let inputCaches = parse(filePaths: inputFiles)

func deduplicate(_ inputCaches: [DxvkStateCache]) -> DxvkStateCache {
    let versions = inputCaches.map {$0.header.version}
    guard versions.dropFirst().allSatisfy({$0 == versions.first!}) else {
        print("Inconsistent state cache versions")
        exit(-1)
    }
    let allEntries = inputCaches.map {$0.entries}.reduce([], +)
    print("Read \(allEntries.count) entries")
    let deduplicatedEntries = Array(Set(allEntries))
    print("Deduplicated to \(deduplicatedEntries.count) entries")
    return DxvkStateCache(header: inputCaches.first!.header, entries: deduplicatedEntries)
}

let outputCache = deduplicate(inputCaches)
do {
    try Data(outputCache.rawData).write(to: URL(fileURLWithPath: outFile))
} catch {
    print(error)
    exit(-1)
}
