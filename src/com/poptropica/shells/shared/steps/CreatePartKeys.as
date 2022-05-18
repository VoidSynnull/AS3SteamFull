package com.poptropica.shells.shared.steps
{
	import engine.managers.FileManager;
	
	import game.data.character.part.PartKeyLibrary;
	import game.proxy.DataStoreProxyPop;
	import game.util.SkinUtils;

	public class CreatePartKeys extends ShellStep
	{
		/**
		 * Load part key files, necessary when converting AS2 look string into AS3 LookData
		 */
		public function CreatePartKeys()
		{
			super();
			stepDescription = "Setting up avatar parts";
		}
		
		/**
		 * Load xml for part keys, this links frame number to frame label, necessary while look Strings are stil coming from AS2
		 */
		override protected function build():void
		{
			var fileManager:FileManager = shellApi.getManager(FileManager) as FileManager;
			// key files for parts, used when pulling in lookStrings from server, as parts in AS2 can refer to frame index 
			var partKeyFiles:Array = new Array();
			for (var i:int = 0; i < SkinUtils.PARTS.length; i++) 
			{
				if( SkinUtils.PARTS[i] == SkinUtils.EYES )	{ continue; }
				
				partKeyFiles.push(fileManager.dataPrefix + PATH + SkinUtils.PARTS[i] + ".xml" );
			}
			
			trace("Shell :: CreatePartKeys :: load keys for parts: " + partKeyFiles);
			fileManager.loadFiles( partKeyFiles, onPartKeysLoaded);
		}
		
		private function onPartKeysLoaded():void
		{
			// create a library to check part values against, this is to handle the use of frames# in as2
			// checking the parts values should only be necessary when receiving a look string from the server or as2LSO
			// NOTE :: We currently store this library in siteProxy, but it may make more sense somewhere else. -bard
			trace("all part keys found");
			(shellApi.siteProxy as DataStoreProxyPop).partKeyLibrary = createPartKeyLibrary();
			trace("part key library created");
			built();
		}
		
		/**
		 * Create the part key for converting parts names from frame number to name.
		 * This is necessary do to the fact that in AS2 some parts with labels can be referred to by frame number ( th emouth part is an example) 
		 * @return 
		 */
		private function createPartKeyLibrary():PartKeyLibrary
		{
			// populate PartKeyLibrary from part key xmls & add to SiteProxy	
			// NOTE :: Only necessary while we are still pulling look strings from AS2
			var partKeyLibrary:PartKeyLibrary = new PartKeyLibrary();
			var partType:String;
			var fileManager:FileManager = shellApi.getManager(FileManager) as FileManager;
			for (var i:int = 0; i < SkinUtils.PARTS.length; i++) 
			{
				partType = SkinUtils.PARTS[i];
				if( partType == SkinUtils.EYES )	{ continue; }
				partKeyLibrary.addKeySet( partType, XML(fileManager.getFile(fileManager.dataPrefix + PATH + SkinUtils.PARTS[i] + ".xml" )) );
			}
			return partKeyLibrary;
		}
		
		private const PATH:String = "entity/character/partKeys/";
	}
}