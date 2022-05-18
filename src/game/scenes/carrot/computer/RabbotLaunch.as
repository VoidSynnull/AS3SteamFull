package game.scenes.carrot.computer
{
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.motion.ShakeMotion;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.carrot.computer.particles.RocketExhaust;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.actions.Jet;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author Bard
	 * 
	 * Rabbot launch animation.
	 */
	
	public class RabbotLaunch extends Popup
	{
		private var velY:Number;
		private var accelY:Number;
		private var startX:Number;
		
		public function RabbotLaunch( container:DisplayObjectContainer = null )
		{
			super( container );
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/carrot/computer/";
			super.pauseParent = false;
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		// initiate asset load of group specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("rabbotLaunch.swf"));
		}

		override public function loaded():void
		{
			super.screen = super.getAsset("rabbotLaunch.swf", true) as MovieClip;
			
			this.letterbox(this.screen.content, new Rectangle(-8, -8, 286, 542), false);
			
			this.createBitmap(this.screen.content.background);
			var rabbot:Sprite = this.createBitmapSprite(this.screen.content.rabbot, 1.5);
			
			var opening:Entity = EntityUtils.createSpatialEntity( super.parent, super.screen.content.opening );
			var spatial:Spatial = opening.get( Spatial );
			spatial.scaleX = 0;
			
			var tween:Tween = new Tween();
			tween.to( spatial, 2, { scaleX: 1 });
			opening.add( tween );
			// create robot entity
			_rabbot = EntityUtils.createMovingEntity( super.parent, rabbot );
			
			// add shake
			_rabbot.add( new ShakeMotion(  new DiscZone( null, 2.5 ) ) );
			ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( _rabbot );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, startLaunch, true ) );
			SceneUtil.addTimedEvent( this, new TimedEvent( 7, 1, onLaunchComplete, true ) );
			
			super.loaded();
		}
		
		// start movement of rabbot & particle effects after a certain amount of time
		private function startLaunch():void
		{
			var motion:Motion =  _rabbot.get( Motion );
			motion.minVelocity = new Point( 0, -100 );
			motion.acceleration = new Point( 0, -38 );		
			startEffects();
		}
		
		private function startEffects():void
		{
			var display:Display = _rabbot.get(Display);
			var robotDisplay:DisplayObject 	= display.displayObject;
			var border:MovieClip 		= super.screen.content.border;
			
			var size:int = 10;
			
			var followTarget:Spatial = _rabbot.get(Spatial);
			var xOffset:int = robotDisplay.width / 2 - (size / 2);
			var yOffset:int = robotDisplay.height * .92;
			var emitter:RocketExhaust = new RocketExhaust();
			_emitter = EmitterCreator.create( this, super.screen.content.effectsLayer, emitter, xOffset, yOffset, null, "exhaust", followTarget );
			
			// set emitter standards
			
			var velocityZone:LineZone = new LineZone( new Point( 15, 150), new Point( -15, 250 ) );
			var positionZone:LineZone = new LineZone( new Point( -10, 0), new Point( 10, 0 ) );
			emitter.init(size, velocityZone, positionZone );

			// make particles move left or right when they reach bottom  
			var zoneHeight:int = 100;
			var zoneWidth:int = 100;
			var centerX:int = border.width / 2;
			var leftZone:RectangleZone = new RectangleZone( centerX - zoneWidth, border.height - zoneHeight, centerX, border.height );
			var rightZone:RectangleZone = new RectangleZone( centerX, border.height - zoneHeight, centerX + zoneWidth, border.height );
			//var leftZone:RectangleZone = new RectangleZone( border.x - 100, border.height - zoneHeight, border.x + border.width / 2, border.y + border.height );
			//var rightZone:RectangleZone = new RectangleZone( border.x + border.width / 2, border.y + border.height - zoneHeight, border.x + border.width, border.y + border.height );
			emitter.addAction( new Jet( -200, -200, leftZone ) );
			emitter.addAction( new Jet( 200, -200, rightZone ) );
			// TODO :: particles could use some tweaking
		}
		
		private function onLaunchComplete():void
		{
			super.close();
		}
		
		public var complete:Signal
		private var _rabbot:Entity;
		private var _emitter:Entity
	}
}