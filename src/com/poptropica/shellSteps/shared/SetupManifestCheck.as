package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import engine.managers.FileManager;
	
	import game.managers.ManifestCheckManager;
	import game.util.DataUtils;

	/**
	 * FOR DEBUG
	 * Setup FileManager to check manifests on each file load request.
	 * Checks appropriate manifests for url, is not found an error is displayed in the console.
	 * @author umckiba
	 */
	public class SetupManifestCheck extends ShellStep
	{
		// DEBUG ONLY
		
		public function SetupManifestCheck()
		{
			super();
			stepDescription = "Loading file manifests";
		}
		
		override protected function build():void
		{	
			// If verifyPathInManifest is true, set FileManager to check paths for existence in manifests
			if( AppConfig.verifyPathInManifest )
			{
				setupManifestValidation();
			}
			else
			{
				this.built();
			}
		}

		protected function setupManifestValidation():void
		{
			var fileManager:FileManager = shellApi.fileManager;
			fileManager.addManifestChecker();
			// NOTE :: Not sure we really want to exclude all ad parts
			//fileManager.manifest_exclusions = new Array( MANIFEST_FILE, "data/dlc", adManager.adKey );
			fileManager.manifestCheckManager.manifest_exclusions = new Array( ManifestCheckManager.MANIFEST_FILE, "data/dlc" );
			fileManager.loadFile(fileManager.dataPrefix + this.gameConfigPath, loadManifests);
		}
		
		protected function loadManifests(gameXml:XML):void
		{
			if( gameXml != null )
			{
				var fileManager:FileManager = FileManager(this.shellApi.getManager(FileManager));
				fileManager.manifestCheckManager.manifests_global = new Array( "start", "hub", "map");//, "examples", "testIsland" );
				fileManager.manifestCheckManager.loadManifests(DataUtils.getArray(gameXml.islands), DataUtils.getArray(gameXml.bundles), this.built);
			}
			else
			{
				trace("SetupManifestCheck Step :: loadManifests : gameXml failed to load.");
			}
		}
		
		protected function get gameConfigPath():String
		{
			var filePrefix:String = ( AppConfig.mobile ) ? "mobile" : "browser";
			return String("game/" + filePrefix + "/game.xml");
		}
	}
}