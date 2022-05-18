package game.scenes.carrot.sewer
{	
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.sewer.components.Rat;
	import game.scenes.carrot.sewer.systems.RatSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Sewer extends PlatformerGameScene
	{
		public function Sewer()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/sewer/";
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
			
			_events = super.events as CarrotEvents;
			
			setupTrapDoors();
			setupRat();
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new WaveMotionSystem() );
			super.addSystem( new RatSystem(), SystemPriorities.update );
		}
		
		private function setupTrapDoors():void
		{
			var clip:MovieClip;
			var hit:Entity;
			var trapEnt:Entity;
			_traps = new Vector.<Entity>();
			
			for(var n:uint = 1; n <= NUM_TRAP_DOORS; n++)
			{
				hit = getEntityById( "trapPlatform" +  n);
				clip = _hitContainer[ "trapDisplay" + n];				
				convertContainer(clip);
				trapEnt = EntityUtils.createSpatialEntity(this, clip);
				trapEnt.add(new Id("trapDisplay" + n));
				_traps.push(trapEnt);
				
				if( n < 3 )
				{
					trapEnt.get(Spatial).rotation = -90;
					hit.remove(Platform);
				}
				
				var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				audioGroup.addAudioToEntity( hit );
			}
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 0, switchTrapDoors));
		}
		
		private function switchTrapDoors():void
		{
			for(var i:uint = 0; i < NUM_TRAP_DOORS; i++)
			{
				var trapEnt:Entity = _traps[i];
				var rotateTo:Number = trapEnt.get(Spatial).rotation == 0 ? -90 : 0;				
				TweenUtils.entityTo(trapEnt, Spatial, .6, {rotation:rotateTo, onComplete:trapTweenDone, onCompleteParams:[trapEnt]});
				
				getEntityById( "trapPlatform" +  (i+1)).remove(Platform);
			}
		}
		
		private function trapTweenDone(trapEnt:Entity):void
		{
			var url:String = trapEnt.get(Spatial).rotation == -90 ? "gears_02.mp3" : "gears_01.mp3";
			AudioUtils.playSoundFromEntity(trapEnt, SoundManager.EFFECTS_PATH + url, 500, 0, 1, Linear.easeInOut);
			
			if(trapEnt.get(Spatial).rotation == 0)
			{
				var id:String = trapEnt.get(Id).id;
				id = id.substring("trapDisplay".length);
				getEntityById( "trapPlatform" + id).add(new Platform());
			}
		}
		
		private function setupRat():void
		{
			var motion:Motion = new Motion();

			_rat = super.getEntityById( "rat" );
			_ratHit = super.getEntityById( "ratHit" );
			
			var displayObject:MovieClip = MovieClip( EntityUtils.getDisplayObject( _rat ));
				
			// create timeline entities
			TimelineUtils.convertClip( displayObject.leg_F, this, null, _rat );
			TimelineUtils.convertClip( displayObject.leg_R, this, null, _rat );
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( _rat );

			motion.velocity = new Point( 180, 0 );
			var threshold:Threshold = new Threshold( "x", ">" );
			threshold.threshold = 1435;
			threshold.entered.addOnce( Command.create( moveRat, true ));
			_ratHit.add( motion).add( threshold ).remove( Sleep );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 15, 1, ratSqueek ));
			
			var wave:WaveMotion = new WaveMotion();
			wave.add( new WaveMotionData( "y", 1.5, 50 ));
			
			_rat.add( wave ).add( new SpatialAddition() );
			_ratHit.add( new Rat());
		}
		
		private function ratSqueek():void
		{
			super.shellApi.triggerEvent( _events.RAT_SQUEEK );
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 15, 1, ratSqueek ));
		}
		
		private function moveRat( moveLeft:Boolean ):void
		{
			var spatial:Spatial = _rat.get( Spatial );
			var motion:Motion = _ratHit.get( Motion );
			var threshold:Threshold;
			
			if ( moveLeft )
			{
				threshold = new Threshold( "x", "<" );
				threshold.threshold = 535;
				threshold.entered.addOnce( Command.create( moveRat, false ));
			}
			else
			{
				threshold = new Threshold( "x", ">" );
				threshold.threshold = 1435;
				threshold.entered.addOnce( Command.create( moveRat, true ));
			}
			
			motion.velocity.x = -motion.velocity.x;
			spatial.scaleX = -spatial.scaleX;
			_ratHit.add( threshold );
		}
		
		private const NUM_TRAP_DOORS:int = 4;
		private var _traps:Vector.<Entity>;
		
		private var _rat:Entity;
		private var _ratHit:Entity;
		private var _events:CarrotEvents;
	}
}