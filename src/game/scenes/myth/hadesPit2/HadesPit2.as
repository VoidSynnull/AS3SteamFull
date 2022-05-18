package game.scenes.myth.hadesPit2
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.WaterCollider;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.WaveMotion;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MoverHitData;
	import game.data.scene.hit.WaterHitData;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;
	import game.scenes.carnival.shared.ferrisWheel.systems.StickyPlatformSystem;
	import game.scenes.myth.riverStyx.RiverStyx;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.WaterHitSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class HadesPit2 extends MythScene
	{
		private const BOAT_DENSITY:Number 	= .8;
//		private const BOAT_RESISTANCE:Number = .11;
		private const WATER_DENSITY:Number 	= 1;
		private const WATER_VISCOSITY:Number = .9;
		private const PLAYER_WEIGHT:Number = .2;
//		private var _audioGroup:AudioGroup;
		
	//	private const LOG_DENSITY:Number 		= .25;
//		private const PLAYER_WEIGHT:Number 		= .45;
		private const BUOYANCY_DAMPENER:Number 	= .12;
		
		public function HadesPit2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/hadesPit2/";
			
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
			super.shellApi.eventTriggered.add( eventTriggers );
			
//			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			addSystem(new WaveMotionSystem(), SystemPriorities.move);
			addSystem(new ParticleSystem(), SystemPriorities.update);
			addSystem( new StickyPlatformSystem(), SystemPriorities.moveComplete );
//			addSystem(new SceneObjectMotionSystem());
			
			var waterHit:WaterHitSystem = super.getSystem( WaterHitSystem ) as WaterHitSystem;
			if( !waterHit )
			{
				waterHit = new WaterHitSystem();
				addSystem( waterHit, SystemPriorities.moveComplete );
			}
			waterHit.playerWeight = PLAYER_WEIGHT;
			
			setupBoat();
			
			var grad:DisplayObjectContainer = _hitContainer["gradient"];
			var bitmap:Bitmap = BitmapUtils.createBitmap(grad, 1);
			DisplayUtils.swap(bitmap, grad);
			var gradEnt:Entity = EntityUtils.createDisplayEntity(this,grad,_hitContainer);
			Display(gradEnt.get(Display)).moveToFront();
		}
		
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.LOAD_RIVER_STYX )
			{
				SceneUtil.lockInput( this );
				var dialog:Dialog = getEntityById( "charon" ).get( Dialog );
				CharUtils.setDirection( getEntityById( "charon" ), true );
				dialog.complete.add( timeToGo );
			}
		}
		
		private function timeToGo( dialogData:DialogData ):void
		{
			super.shellApi.loadScene( RiverStyx );
		}
		
		private function setupBoat():void
		{
			var clip:DisplayObject = _hitContainer[ "boatHit" ];
			var charon:Entity = super.getEntityById( "charon" );
			var display:Display;
			
			var boatHit:Entity = EntityUtils.createSpatialEntity( this, clip as MovieClip );
			display = boatHit.get( Display );
			display.alpha = 0;
				
		
			var spatial:Spatial = boatHit.get( Spatial );
			
			clip = _hitContainer[ "boat" ];
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip );
			var displayObjectBounds:Rectangle = clip.getBounds( clip );
			var offsetMatrix:Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			
			var sprite:Sprite = new Sprite();
			
			var bitmapData:BitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
			bitmapData.draw( wrapper.data, null );
			
			var bitmap:Bitmap = new Bitmap( bitmapData, "auto", true );
			bitmap.transform.matrix = offsetMatrix;
			sprite.addChild( bitmap );
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			var boat:Entity = EntityUtils.createSpatialEntity( this, sprite, _hitContainer );
			display = boat.get( Display );
			display.displayObject.mouseChildren = false;
			
			var followTarget:FollowTarget = new FollowTarget( spatial, 1, false, true );
			boat.add( followTarget );
			boatHit.add( new Id( "boatHit" ));
		
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.makeHit( boatHit, HitType.SCENE, new HitData());
			hitCreator.makeHit( boatHit, HitType.PLATFORM_TOP );
			hitCreator.addHitSoundsToEntity( boatHit, _audioGroup.audioData, shellApi );
			
			display = boatHit.get( Display );
			display.alpha = 0;
			
	//		var waterCollider:WaterCollider;
			var waveMotion:WaveMotion = new WaveMotion();
			var spatialAddition:SpatialAddition = new SpatialAddition(); 
			var waveMotionData:WaveMotionData = new WaveMotionData();
			
			
			// WATER
			var water:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "aqua" ]);
			display = water.get( Display );
			display.alpha = 0;
			
			water.add( new Id( "water" ));
			var waterHitData:WaterHitData = new WaterHitData();
			waterHitData.density = WATER_DENSITY;
			waterHitData.viscosity = WATER_VISCOSITY;
			waterHitData.splashColor1 = 0xFF339900;
			waterHitData.splashColor2 = 0x33ccff33;
			
//			var moverHitData:MoverHitData = new MoverHitData();
//			moverHitData.stickToPlatforms = true;
			
			
			hitCreator.makeHit( water, HitType.WATER, waterHitData );
			hitCreator.addHitSoundsToEntity( water, _audioGroup.audioData, shellApi );
//			hitCreator.makeHit( water, HitType.MOVER, moverHitData );
			
			water.add( new Sleep( false, true ));
			
			// ADD WAVE MOTION TO THE BOAT
			waveMotionData.property = "rotation";
			waveMotionData.magnitude = 2;
			waveMotionData.rate = .05;
			waveMotionData.radians = 0;
			waveMotion.data.push( waveMotionData );
			
		//	boatHit.add( spatialAddition );
			var edge:Edge = new Edge();
			display = boatHit.get( Display );
			edge.unscaled = display.displayObject.getBounds(display.displayObject);
			boatHit.add( edge );
			
			boat.add( waveMotion );
			boat.add( spatialAddition );
			
			display = boat.get( Display );
			DisplayUtils.moveToTop( display.displayObject );
			
			EntityUtils.followTarget( charon, boatHit, 1, new Point( 80, -60 )); 
			
			var waterCollider:WaterCollider = new WaterCollider();
			waterCollider.density = PLAYER_WEIGHT;
			waterCollider.dampener = BUOYANCY_DAMPENER;
			waterCollider.ignoreSplash = true;
			
			boatHit.add( waterCollider );	
//			boatHit.add( new SceneObjectMotion() );
//			boatHit.add(  new StickyPlatform())
			EntityUtils.addParentChild( boat, boatHit );
			EntityUtils.addParentChild( boatHit, water);
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, killStartingPlatform ));
			
//			if( !shellApi.sceneManager.previousScene )
//			{
//				CharUtils.position( player, 258, 1378 );
//			}
//			else if( !shellApi.sceneManager.previousScene.toLowerCase() == "hadespit1" )
//			{
//				CharUtils.position( player, 258, 1378 );
//			}
				
		}
		
		private function killStartingPlatform():void
		{
			super.removeEntity( getEntityById( "starting" ));
		}
	}
}