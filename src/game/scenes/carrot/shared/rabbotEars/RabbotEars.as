package game.scenes.carrot.shared.rabbotEars
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.SpatialAddition;
	import engine.util.Command;
	
	import game.components.motion.WaveMotion;
	import game.components.motion.ShakeMotion;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.shared.rabbotEars.components.Current;
	import game.scenes.carrot.shared.rabbotEars.systems.CurrentSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class RabbotEars extends Popup
	{
		public function RabbotEars( container:DisplayObjectContainer = null, args:Array = null )
		{
			super( container );
			_completeEvent = args[0] as String;	// event to be trigger on complete is passed as param
			_droneNumber = Number( args[1] );
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/carrot/shared/";
			super.pauseParent = true;
			super.darkenBackground = true;
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.addSystem( new CurrentSystem());
			super.addSystem( new WaveMotionSystem());
			super.loadFiles( new Array("rabbotEars.swf") );
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("rabbotEars.swf", true);
			super.loaded();
		
			// setup rabbot ears
			var mc:MovieClip = this.screen.content;
			
			this.fitToDimensions(mc);
			this.pinToEdge(mc, DisplayPositions.BOTTOM_CENTER, 0, -50);
			
			_helmet = EntityUtils.createMovingEntity( this, mc );
			
			_helmet.add(new SpatialAddition());
			
			var wave:WaveMotion = new WaveMotion();
			wave.data.push( new WaveMotionData( "y", 10, .02 ));
			_helmet.add( wave );
			
			super.loadCloseButton();
			var current:Current = new Current( 150, 350, 330, 20, 0, 50, 80, 1, 0x35A5FF );
			
			_electricity = EntityUtils.createSpatialEntity( this, new Sprite(), mc.currentContainer );
			_electricity.add( current );
			_powerBtn = ButtonCreator.createButtonEntity( mc.powerBtn, this, onButtonClick );
		}
	
		public function onButtonClick( entity:Entity ):void
		{
			_helmet.remove( WaveMotion );
			_helmet.add( new ShakeMotion() );
			super.removeEntity( _electricity );
			shakeHelmet( 14 );
			
			var audioComponent:Audio = new Audio();
			_helmet.add( audioComponent );
			audioComponent.play("effects/power_down_02.mp3");
			
			ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( _helmet );
		}
		
		public function shakeHelmet( number:int ):void
		{
			var shake:ShakeMotion = _helmet.get( ShakeMotion );
			shake.shakeZone = new RectangleZone( -number, -number, number, number );
			var newNum:int = number - 1;
			
			if ( number > 0 )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( .04, 1, Command.create( shakeHelmet, newNum )));
			}
			else
			{
				super.shellApi.triggerEvent( _completeEvent + String(_droneNumber), true );
				super.shellApi.triggerEvent( CarrotEvents(shellApi.islandEvents).DRONE_FREE, false, false );
				SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, closePopup )); 
			}
		}

		public function closePopup():void
		{
			_helmet.remove( ShakeMotion );
			super.close();
		}
		
		private var _helmet:Entity;
		private var _electricity:Entity;
		private var _powerBtn:Entity 
		private var _completeEvent:String;
		private var _droneNumber:Number;
		private var _t:Number;
		private var _contentStartY:Number;
	}
}
