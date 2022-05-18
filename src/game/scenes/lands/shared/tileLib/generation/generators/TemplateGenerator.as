package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * !! TEMPORARILY combined the new treasure generation with the template generator for speed's sake.
	 * Later treasure will be pulled out into its own 'thing'
	 */
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.templates.TemplateFileInfo;
	import game.scenes.lands.shared.tileLib.templates.TemplateProc;
	import game.scenes.lands.shared.tileLib.templates.TemplateRegister;
	import game.scenes.lands.shared.tileLib.templates.TileTemplate;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;

	public class TemplateGenerator extends MapGenerator {

		/**
		 * register of templates available.
		 */
		private var register:TemplateRegister;

		private var group:LandGroup;

		/**
		 * place to apply a template on the map once the template loads.
		 */
		private var applyX:int;
		private var applyY:int;

		/**
		 * offset for accessing random map. won't need this if templates get their own random map.
		 */
		private var rowOffset:int = 17;

		private var generateList:Vector.<TemplateProc>;

		/**
		 * template generation takes place over several frames, since templates have to be loaded
		 * and then placed onscreen. this function is called when generation completes.
		 * 
		 * didGenerate - false indicates no templates were generated.
		 * if true, the scene data should be saved immediately so saved games are guaranteed to keep
		 * the same generated buildings, even if the generating code changes.
		 * 
		 * onGenerateComplete( didGenerate:Boolean )
		 * 
		 */
		private var onGenerateComplete:Function;

		/**
		 * minimum separation between templates?
		 */
		private var minSeparation:int = 8;

		/**
		 * templates need to load but also treasure props. onGenerateComplete() cant proc until both finish. annoying.
		 */
		private var loadsWaiting:int = 0;
		private var hasTemplates:Boolean = false;

		public function TemplateGenerator( group:LandGroup, register:TemplateRegister, onGenerate:Function ) {

			super();

			this.group = group;

			this.onGenerateComplete = onGenerate;

			this.register = register;

			this.generateList = new Vector.<TemplateProc>();

		} //

		override public function generate( gameData:LandGameData=null ):void {

			var n:Number = Math.random();
			var isTreasure:Boolean = false;
			var rate:Number = 0.77;

			if ( Math.random() < 0.8 ) {
				this.placeTreasureProps( gameData.tileMaps["decal"] );
			} //

			// this is a small chance to skip template generation entirely, to keep them more rare.
			if ( n < 0.3 ) {

				this.tryCallback();
				return;

			} else if ( n < 0.5 ) {
				isTreasure = true;
			} //

			var r:int = Math.random();

			var templateMap:RandomMap = gameData.worldRandoms.treeMap;
			//this.randomMap = gameData.worldRandoms.randMap;

			/**
			 * stays away from being too close to either edge of the screen, because currently the templates
			 * won't continue in the next scene - so don't proc them bordering the edges.
			 */
			for( var c:int = this.tileMap.cols-10; c >= 2; c-- ) {

				r = super.getTopRow( this.tileMap, c );
				if ( r < 0 ) {
					continue;
				}

				// need to check there are no other nearby tiles?
				if ( templateMap.getNumberAt( c, r+rowOffset ) > rate ) {

					// PLACE A TEMPLATE.
					this.queueRandomTemplate( r, c, isTreasure );

					// save some time. not going to build another tree in this area.
					c -= this.minSeparation;

				} //

			} // for-loop.

			// load all files needed for generating the templates, then place them.
			if ( this.generateList.length > 0 ) {

				this.loadTemplateFiles( this.generateList );

			} else {

				this.tryCallback();

			} //

		} // generate()

		private function placeTreasureProps( propMap:TileMap ):void {

			var treasures:int = 6*Math.random();
			var col:int, row:int;
			var clipType:ClipTileType;

			var rect:Rectangle = new Rectangle();
			var clip:MovieClip;

			while ( treasures-- >= 0 ) {

				col = Math.random()*this.tileMap.cols;

				row = super.getTopRow( this.tileMap, col );
				if ( row < 0 ) {
					continue;
				}
				// go some random depth downwards and then check that its still a covered space.
				row = row + Math.random()*( this.tileMap.rows - row );
				if ( this.tileMap.getTile( row, col ).type == 0 ) {
					continue;
				}

				// now place a treasure..
				// for NOW i just make sure all tile clips are preloaded in the template registry.
				clipType = this.register.getRandomProp();
				clip = clipType.clip;
				if ( clip == null ) {
					// the preload didn't work for some reason.
					continue;
				}

				// ugh. i know.
				rect.setTo( 2*col*propMap.tileSize, 2*row*propMap.tileSize, clip.loaderInfo.width, clip.loaderInfo.height );
				clipType.dropDecal( propMap, rect );

			} // while-loop.

		} //

		/*private function propsLoaded():void {

			this.loadsWaiting--;
			this.tryCallback();

		} //*/

		private function tryCallback():void {

			if ( this.loadsWaiting <= 0 && this.onGenerateComplete ) {
				this.onGenerateComplete( this.hasTemplates );
			} //

		} //

		/**
		 * pick a random template and queue it for loading.
		 */
		private function queueRandomTemplate( r:int, c:int, treasure:Boolean=false ):void {

			// do better random stuff later.
			var info:TemplateFileInfo;

			if ( treasure ) {
				info = this.register.getRandomTreasure();
			} else {
				info = this.register.getRandom();
			}

			this.generateList.push( new TemplateProc( info.fileName, c*this.tileMap.tileSize, r*this.tileMap.tileSize ) );

		} //

		private function loadTemplateFiles( files:Vector.<TemplateProc> ):void {

			this.loadsWaiting++;

			var fileList:Array = [];
			
			var prefix:String = group.templateDataURL;
			var proc:TemplateProc;
			var file:String;

			for( var i:int = files.length-1; i >= 0; i-- ) {

				proc = files[i];
				file = prefix + proc.file + ".xml";

				if ( fileList.indexOf( file ) >= 0 ) {
					// template file already being loaded.
					continue;
				}
				fileList.push( file );

			} //

			group.shellApi.loadFiles( fileList, this.templateFilesLoaded );

		} //
		
		private function templateFilesLoaded():void {

			var prefix:String = group.templateDataURL;
			var template:TileTemplate;
			var proc:TemplateProc;
			var fileName:String;
			var templateXML:XML;

			var maps:Dictionary = this.group.gameData.tileMaps;

			// used to decode templates.
			var encoder:LandEncoder = new LandEncoder();

			var maxX:Number = this.group.sceneBounds.right;
			var lastX:Number = 0;

			for( var i:int = this.generateList.length-1; i >= 0; i-- ) {
				
				proc = generateList[i];
				fileName = prefix + proc.file + ".xml";

				templateXML = this.group.shellApi.getFile( fileName, false );
				if ( templateXML == null ) {
					continue;
				}
				template = new TileTemplate();
				if ( !encoder.decodeTemplate( template, templateXML ) ) {
					trace( "error decoding template: " + fileName );
					continue;
				} //

				if ( proc.templateX < lastX ) {
					proc.templateX = lastX + 64;
				}
				lastX = proc.templateX + template.width;
				if ( lastX > maxX ) {
					break;
				}

				template.pasteTemplate( maps, proc.templateX, proc.templateY - template.height + this.tileMap.tileSize*template.rowOffset );

			} // for-loop.

			this.hasTemplates = true;
			// clear generate list for next scene.
			this.generateList.length = 0;

			this.loadsWaiting--;
			this.tryCallback();
			
		} //

		/*private function loadTemplate( file:TemplateFileInfo ):void {
		} //*/

		private function templateLoaded( file:XML ):void {

			if ( file == null ) {
				return;
			}

			var template:TileTemplate = new TileTemplate();

			var encoder:LandEncoder = new LandEncoder();
			if ( !encoder.decodeTemplate( template, file ) ) {

				trace( "error decoding template" );
				return;

			} //

			template.pasteTemplate( this.group.gameData.tileMaps, 0, 0 );

		} //

		public function setMap( tileMap:TileMap ):void {

			this.tileMap = tileMap;
			this.tileSet = tileMap.tileSet;

		} //

	} // class

} // package