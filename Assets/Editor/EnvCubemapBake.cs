using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;

class CubemapUtility {
    [MenuItem( "Cubemaps/Bake all static cubemaps" )]
    static void BakeCubemaps() {
        // default path to save cubemaps if the scene hasn't been saved yet
        string assetPath = "Assets/radiator/cubemaps/";

        // ... otherwise, save the cubemaps in a folder next to the scene;
        // NOTE: this will NOT delete the existing cubemaps, so you might end up having to clean the folder yourself
        if (EditorApplication.currentScene != "") {
            List<string> pathTemp = new List<string>(EditorApplication.currentScene.Split(char.Parse("/")));
            pathTemp[pathTemp.Count-1] = pathTemp[pathTemp.Count-1].Substring(0, pathTemp[pathTemp.Count-1].Length - 6);
            assetPath = string.Join( "/", pathTemp.ToArray() ) + "/";
        }
    
        // begin baking cubemaps
        float progress = 0f; // how far along we are in the whole baking process, from 0-1
        int counter = 0; // number of cubemaps we've processed so far
        EnvCubemap[] cubemaps = GameObject.FindObjectsOfType( typeof( EnvCubemap ) ) as EnvCubemap[]; // grab all cubemaps in the scene
        foreach ( EnvCubemap env_cubemap in cubemaps ) {
            EditorUtility.DisplayProgressBar("Baking cubemaps...", "Baking cubemap at " + env_cubemap.transform.position.ToString(), progress);

            if (env_cubemap.enabled) {
                Cubemap cube = BakeCubemapStatic(env_cubemap);
                env_cubemap.cubemap = cube; // I probably should've named these variables better
                string cubeAsset = assetPath + cube.name + ".cubemap"; // cubemap files must end with .cubemap file extension
                AssetDatabase.CreateAsset( cube, cubeAsset);
                EditorUtility.SetDirty( cube ); // use SetDirty() to tell Unity to save new info
                EditorUtility.SetDirty( env_cubemap );
            }

            counter++; // we finished processing a cubemap! yay!
            progress = (counter * 1f) / cubemaps.Length; // multiply by 1f to cast int to a float
        }

        EditorUtility.ClearProgressBar();
    }

    static Cubemap BakeCubemapStatic(EnvCubemap env_cubemap) {
        // create new cubemap
        Cubemap cubemap = new Cubemap( env_cubemap.cubemapRes, TextureFormat.RGB24, true );

        // create temporary camera for rendering
        var go = new GameObject( "CubemapCamera", typeof( Camera ) );
        // place it on the object
        go.transform.position = env_cubemap.transform.position;
        go.transform.rotation = Quaternion.identity;
        // render into cubemap        
        go.camera.near = env_cubemap.near;
        go.camera.far = env_cubemap.far;
        go.camera.clearFlags = env_cubemap.clearFlags;
        go.camera.backgroundColor = env_cubemap.clearColor;
        go.camera.cullingMask = env_cubemap.cullingMask;
        go.camera.RenderToCubemap( cubemap, 63 );
        // destroy temporary camera
        env_cubemap.KillThis( go );

        // some cubemappy stuff
        cubemap.SmoothEdges();
        cubemap.mipMapBias = 0.5f;
        cubemap.name = env_cubemap.cubemapRes.ToString() + "@" + env_cubemap.transform.position.ToString();
        cubemap.Apply( true, false );

        return cubemap;
    }

    // if the cubemap baker crashes, you'll have to use this to clear the progress bar
    [MenuItem( "Cubemaps/Debug, clear progress bar" )]
    static void Clear() {
        EditorUtility.ClearProgressBar();
    }
}