package game.scenes.examples.mergedScene
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.util.SceneMergeUtils;
	
	/**
	 * The SceneDataManager is responsible for managing the loading and parsing of a scene.xml and the loading of all the files that
	 *   it specifies.  It can also 'merge' multiple scene.xml files into a single scene.  This is useful if you have multiple display layers or 
	 *   xml files that you want to be merged into a scene.
	 * 
	 * This approach is used for Ads to allow an AdBuilding, for example, to be merged into a new scene and add its own hits, camera layers and npcs
	 *   into the scene.  It could also be used for any 'pre-fab' scene that needs to be added to multiple scenes.
	 * 
	 * The default functionality will simply add the camera layers and xml contents into the existing scenes without changing anything.  You can
	 *    optionally handle the merge process yourself by specifying a 'merge processor' function that can override the default for some or all
	 *    file types.  The example below merges two different scene.xml's into a single scene.  The first case just uses the default merge processing
	 *    and the second case applies a position offset to the merged in files camera layers, hits and npcs.
	 */
	
	public class MergedScene extends PlatformerGameScene
	{
		public function MergedScene()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/mergedScene/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
		}
		
		override protected function addGroups():void
		{
			// load a new scene config from the 'toMerge/' folder.
			super.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, super.groupPrefix + "toMerge/", loadSpecialMerge);
		}
		
		private function loadSpecialMerge(files:Array):void
		{
			// merge all the scene files from the 'toMerge/' folder using the default merge process 
			super.sceneDataManager.mergeSceneFiles(files, super.groupPrefix + "toMerge/", super.groupPrefix);
			// load another set of scene files from the 'toMergeSpecial/' folder
			super.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, super.groupPrefix + "toMergeSpecial/", handleLoaded);
		}
		
		private function handleLoaded(files:Array):void
		{
			// do a merge of the files from 'toMergeSpecial' using a custom 'mergeProcessor' method defined in this scene.
			super.sceneDataManager.mergeSceneFiles(files, super.groupPrefix + "toMergeSpecial/", super.groupPrefix, offsetPosition);
			// both scene.xml's have been merged into this scene, so proceed with scene setup...
			super.addGroups();
		}
		
		private function offsetPosition(file:*, url:String, originalFile:*, originalUrl:String):Boolean
		{
			var displayOffsetX:Number = 30;
			var displayOffsetY:Number = 505;
			// use this util to apply an offset to the contents of the merged file.  This util applies a set offset
			//   to all npcs, hits, and camera layers so the same 'pre-fab' scene can be pasted into another scene
			//   with a unique position.  This is useful for 'mini scenes' like a vendor cart which may have its
			//   own hits, npcs, and camera layers.
			return(SceneMergeUtils.offsetPosition(displayOffsetX, displayOffsetY, super.shellApi, file, url, originalFile, originalUrl));
		}
	}
}