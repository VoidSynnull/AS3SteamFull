package game.scenes.lands.adMixed1 {
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scene.template.CameraGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.SkyRenderer;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.painters.TerrainPainter;
	import game.scenes.lands.shared.tileLib.parsers.LandParser;
	import game.scenes.lands.shared.tileLib.parsers.TileParser;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;
	import game.util.AudioUtils;
	
	public class AdMixed1 extends PlatformerGameScene {
		
		private var curBiome:String;
		private var worldTime:Number;
		
		private var skyRenderer:SkyRenderer;
		
		/**
		 * true if the current biome data was able to load and initialize.
		 */
		private var biomeLoaded:Boolean = false;
		
		/**
		 * rand map.
		 */
		private var randMap:RandomMap;
		private var terrainMap:RandomMap;
		
		/**
		 * tile type being used to draw the ground in the ad scene.
		 */
		private var grassType:TerrainTileType;
		
		private var assetLoader:LandAssetLoader;
		
		/**
		 * maximum offset (up or down) from the base terrain height.
		 */
		private var maxYOffset:Number = 20;
		/**
		 * length of each section of terrain. smaller values will result in choppier terrain.
		 */
		private var sectionLength:Number = 80;
		
		public function AdMixed1() {
			
			super();
			
		} //
		
		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {
			
			super.groupPrefix = "scenes/lands/adMixed1/";
			
			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.allowLayerGrid = false;
			super.addChildGroup(cameraGroup);
			
			super.init( container );
			
		} //
		
		// initiate asset load of scene specific assets.
		override public function load():void {
			
			super.load();
			
		} //
		
		// all assets ready
		override public function loaded():void {
			
			// the basic scene stuff has loaded, but don't call super.loaded() until the terrain drawing stuff is ready.
			this.loadCurBiome();
			
		} // loaded()
		
		/**
		 * need to load the biome xml file in order to get the sky colors and the grass tile, grass details.
		 */
		private function loadCurBiome():void {
			
			//var so:SharedObject = SharedObject.getLocal( "landCache" );
			//var cacheObj:Object = so.data.cacheObj;
			// QUESTION :: Do you need to pull this userfield data from the server? - bard
			var cacheObj:Object = this.shellApi.getUserField( "realmsCache", this.shellApi.island );
			
			if ( cacheObj == null ) {
				shellApi.logWWW( "no LSO data" );
				super.loaded();
				return;
			}
			
			this.curBiome = cacheObj.curBiome;
			if ( this.curBiome == null ) {
				shellApi.logWWW( "no biome found" );
				super.loaded();
				return;
			}
			
			this.worldTime = cacheObj.worldTime;
			
			this.randMap = new RandomMap( cacheObj.sceneSeed, 128, 128 );
			this.randMap.makeNoise();
			
			this.terrainMap = new RandomMap( cacheObj.curSeed, 128, 128 );
			this.terrainMap.makeOffsetPerlin( new Point( cacheObj.perlinOffsetX, 0 ), 64, 64 );
			
			//this.shellApi.logWWW( "loading biome file: " + this.curBiome );
			
			super.shellApi.loadFile( super.shellApi.dataPrefix + "scenes/lands/biomes/" + this.curBiome + ".xml", this.biomeDataLoaded );
			
		} //
		
		private function biomeDataLoaded( xml:XML ):void {
			
			if ( xml == null || xml == "" ) {
				super.loaded();
				return;
			}
			
			// need this to make the tile parsers work.
			var gameData:LandGameData = new LandGameData();
			
			// utilizing what we can of the land code.
			var parser:LandParser = new LandParser( null, gameData );
			
			// SKY STUFF
			this.initSkyRenderer();
			if ( this.skyRenderer != null ) {

				// shouldn't happen but apparently can.. somehow?
				parser.parseSky( xml.child( "sky" )[0] );
				this.skyRenderer.setSkyColors( gameData.biomeData.topSkyColors, gameData.biomeData.bottomSkyColors );

				gameData.clock.setStartTime( this.worldTime );
				this.skyRenderer.redraw( gameData.clock, this.terrainMap );

			} //

			// find some terrain from the current biome.
			var terrainList:XMLList = xml.descendants("terrain" );
			if ( !terrainList || terrainList.length() == 0 ) {
				super.loaded();
				return;
			}
			
			// use grass-replace tile, if available.
			var grassList:XMLList = terrainList.( @type=="4" );
			if ( grassList != null && grassList.length() != 0 ) {
				terrainList = grassList;
			}
			
			var tileParser:TileParser = new TileParser( gameData );
			tileParser.useLayerProps = false;
			
			this.grassType = new TerrainTileType();
			
			tileParser.parseTerrainType( terrainList[0], this.grassType );
			
			//this.shellApi.logWWW( "loading biome tiles" );
			this.assetLoader = new LandAssetLoader( this.shellApi, this.shellApi.assetPrefix + "scenes/lands/", gameData );
			this.assetLoader.loadSingleTerrain( this.grassType, this.onTileLoaded );
			
		} //
		
		private function onTileLoaded():void {
			
			// now we have the resources to draw terrain across the screen.
			
			var painter:TerrainPainter = this.getTerrainPainter();
			if ( painter == null ) {
				//trace( "error: could not paint biome" );
				super.loaded();
				return;
			}
			
			this.drawTerrain( painter, this.makeTerrainPoints() );
			
			this.biomeLoaded = true;
			super.loaded();
			
			//set ambient sound track for biome
			//removing for now until we can figure out how to make so it doesn't restart when going through the ad scene
			//this.setBiomeAmbientSound();
			
		} //
		
		private function drawTerrain( painter:TerrainPainter, points:Vector.<Point> ):void {
			
			painter.startPaintBatch();
			painter.startPaintType( this.grassType );
			
			var pt:Point = points[0];
			var nxt:Point;
			var drawPt:Point = new Point();		// control point for curving the stroke.
			
			painter.startStroke( pt.x, pt.y );
			
			var max:int = points.length-3;			// the final two points are offscreen draw points.
			
			var topBorder:uint = LandTile.TOP;
			
			for( var i:int = 1; i <= max; i++ ) {
				
				nxt = points[i];
				
				painter.curveStroke( pt, (pt.x + nxt.x)/2, (pt.y + nxt.y)/2, topBorder );
				pt = nxt;
				
			} //
			
			painter.curveStroke( pt, pt.x, pt.y, topBorder );
			
			pt = points[++max];
			painter.curveStroke( pt, pt.x, pt.y, LandTile.RIGHT );
			pt = points[++max];
			painter.curveStroke( pt, pt.x, pt.y, LandTile.BOTTOM );
			
			painter.endPaintType();
			painter.endPaintBatch();
			
		} //
		
		private function getTerrainPainter():TerrainPainter {
			
			/*var collisionGroup:CollisionGroup = this.getGroupById( "collisionGroup" ) as CollisionGroup;
			var hitBitmap:BitmapData = collisionGroup.hitBitmapData;
			
			if ( hitBitmap == null ) {
			return null;
			}*/
			
			// TEST WITH FOREGROUND
			/*var bounds:Rectangle = this.sceneData.bounds;
			var bmd:BitmapData = new BitmapData( bounds.width, bounds.height, true, 0 );
			
			var fgBitmap:Bitmap = new Bitmap( hitBitmap );
			fgBitmap.x = 0;
			fgBitmap.y = 300;
			fgBitmap.name = "foreground";
			
			this.hitContainer.addChild( fgBitmap );*/
			// tEST WITH FOREGROUND
			var bgEntity:Entity = this.getEntityById( "backgroundtwo" );
			var display:Display = bgEntity.get( Display ) as Display;
			
			var renderContext:RenderContext = new RenderContext( display.bitmapWrapper.bitmap.bitmapData );
			renderContext.init();
			
			var paintRect:Rectangle = renderContext.viewPaintRect;
			paintRect.width = this.sceneData.cameraLimits.width;
			paintRect.height = this.sceneData.cameraLimits.height;
			
			/*var hitRect:Rectangle = renderContext.hitPaintRect;
			hitRect.width = 0.5*paintRect.width;
			hitRect.height = 0.5*paintRect.height;*/
			
			return new TerrainPainter( false, renderContext, this.randMap );
			
		} //
		
		/**
		 * make the points of the terrain drawing.
		 */
		private function makeTerrainPoints():Vector.<Point> {
			
			var bounds:Rectangle = this.sceneData.cameraLimits;
			var baseY:Number = this.sceneData.bounds.bottom - this.maxYOffset - 4;
			
			var curX:Number = -20;
			var endX:Number = bounds.width + 20;
			var segment:int = 0;
			
			var points:Vector.<Point> = new Vector.<Point>();
			
			// starting point.
			var pt:Point = new Point( curX, baseY );
			
			while ( curX < endX ) {
				
				points.push( pt );
				
				// pick a point in the current segment.
				curX = ( segment + this.randMap.getRandom() )*this.sectionLength;
				segment++;
				
				pt = new Point( curX, baseY + ( 2*this.randMap.getRandom() - 1 )*this.maxYOffset );
				
				
			} //
			
			// final point was never pushed.
			pt.y = baseY;
			points.push( pt );
			
			// two more points below the camera bounds to fill in the land below.
			points.push( new Point( curX, bounds.bottom + 10 ) );
			points.push( new Point( -20, bounds.bottom + 10 ) );
			
			return points;
			
		} //
		
		private function initSkyRenderer():void {
			
			var bdEntity:Entity = this.getEntityById( "backdrop" );
			if ( bdEntity == null ) {
				return;
			}
			var display:Display = bdEntity.get( Display ) as Display;
			if ( !display ) {
				return;
			} //
			
			var bm:BitmapData = display.bitmapWrapper.bitmap.bitmapData;
			this.skyRenderer = new SkyRenderer( bm );
			this.skyRenderer.init( this.randMap );
			
		} //
		
		/**
		 * Sets the background ambient track for current biome
		 */
		public function setBiomeAmbientSound():void {
			
			//AudioUtils.stop (this, null, SceneSound.SCENE_SOUND);
			var myUrl:String = "realms_"+this.curBiome+".mp3";
			
			AudioUtils.play (this, SoundManager.AMBIENT_PATH + myUrl, 1, true, [SoundModifier.FADE, SoundModifier.AMBIENT], SceneSound.SCENE_SOUND);
			
			//super.shellApi.triggerEvent("set_ambient_"+ this.curBiome);
			
		} //
		
	} // class
	
} // package