using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEditor.Build.Reporting;

[InitializeOnLoad]
public class BuildAssistant : MonoBehaviour
{ 
    static List<string> dependentPackages = new List<string>();
    static List<string> importedPackages  = new List<string>();
  
    //
    static BuildAssistant()
    {    
        string[] packages = Directory.GetFiles(Directory.GetCurrentDirectory(), "*.unitypackage");
        packages = packages.Select(f => Path.GetFileName(f)).ToArray();
        dependentPackages =  new List<string>(packages);
        
        AssetDatabase.importPackageCompleted += OnImportPackageCompleted;
    }
    
    //
    [MenuItem("BuildAssistant/Open Final IK Page")]
    public static void OpenAssetStore()
    {
        System.Diagnostics.Process.Start("com.unity3d.kharma:com.unity3d.kharma:content/14290");
        Application.OpenURL("https://assetstore.unity.com/packages/tools/animation/final-ik-14290");
    }
    
    // 
    static void ImportPackage()
    {
        foreach (string package in dependentPackages)
        {
            AssetDatabase.ImportPackage(package, false);
        }
    }
    
    //
    private static void OnImportPackageCompleted(string packagename)
    {
        importedPackages.Add(packagename + ".unitypackage");
        if (dependentPackages.SequenceEqual(importedPackages)){
            EditorApplication.Exit(0);
        }
    }
    
    //
    public static void Build()
    {
        BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions();
        buildPlayerOptions.scenes = new[] { "Assets/Scenes/VirtualMotionCapture.unity" };
        buildPlayerOptions.locationPathName = "UnityBuild/VirtualMotionCapture.exe";
        buildPlayerOptions.target = BuildTarget.StandaloneWindows64;
        buildPlayerOptions.options = BuildOptions.None;

        BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
        BuildSummary summary = report.summary;

        if (summary.result == BuildResult.Succeeded)
        {
            Debug.Log("Build succeeded: " + summary.totalSize + " bytes");
        }

        if (summary.result == BuildResult.Failed)
        {
            Debug.Log("Build failed");
        }
        EditorApplication.Exit(0);
    }
}
