package game.scenes.carrot.farm
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import com.poptropica.AppConfig;
	import engine.systems.AudioSystem;
	import flash.events.LocationChangeEvent;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.OriginPoint;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.farm.components.Carrot;
	import game.scenes.carrot.farm.systems.CarrotSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Farm extends PlatformerGameScene
	{
		public function Farm()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/farm/";
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
			super.addSystem( new ThresholdSystem() );
			super.addSystem( new WaveMotionSystem() );
			super.addSystem( new TimelineClipSystem() );
			super.addSystem( new CarrotSystem() );
			var carrotSystem:CarrotSystem = super.getSystem( CarrotSystem ) as CarrotSystem;
			carrotSystem._pulled.add( carrotHandler );

			_events = super.events as CarrotEvents;
			
			if(super.shellApi.checkEvent(CarrotEvents(super.events).CAT_FOLLOWING))
			{
				var cat:Entity = super.groupManager.getEntityById("cat", this);
				cat.get(Spatial).x = shellApi.player.get(Spatial).x;
				cat.get(Spatial).y = shellApi.player.get(Spatial).y;
				ToolTipCreator.removeFromEntity(cat);
				
				var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
				charGroup.addFSM( cat );
				CharUtils.followEntity( cat, shellApi.player, new Point(200, 200) );
			}
			
			_carrots = new Vector.<Entity>;
		
			if(super.shellApi.checkEvent(CarrotEvents(super.events).DESTROYED_RABBOT))
			{
				setupCarrots( "finale" );
				setupButterflies();
			}
			else
			{
				setupCarrots( "start" );
				hideButterflies();
			}
			
			setupLeaves();		
		}
		
		private function carrotHandler( carrotID:String ):void
		{
			switch( carrotID )
			{
				case "carrot1":
					super.shellApi.triggerEvent( _events.CARROT_DISAPPEAR_ + 1 );
					break;
				case "carrot2":
					super.shellApi.triggerEvent( _events.CARROT_DISAPPEAR_ + 2 );
					break;
			}
		}
		
		private function setupCarrots( label:String ):void
		{
			var carrot:Entity;
			var carrotComp:Carrot;
			var mc:MovieClip;
			var sprite:Sprite;
			var timeline:Timeline;
			
			if ( label == "finale" )
			{
				for( var i:int = 0; i < 2; i ++ )
				{
					carrot = EntityUtils.createSpatialEntity( this, super._hitContainer[ "carrot" + ( i + 1 )]);
					super.removeEntity( carrot );
				}
			}
			else if ( label == "start" )
			{
				for( var j:int = 0; j < 2; j ++ )
				{
					carrotComp = new Carrot();
					carrotComp.playing = false;

					carrot = EntityUtils.createSpatialEntity( this, super._hitContainer[ "carrot" + ( j + 1 )]);
					carrot.add( new Id( "carrot" + ( j + 1 )));
					
					var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
					audioGroup.addAudioToEntity( carrot );
					
					mc = EntityUtils.getDisplayObject( carrot ) as MovieClip;
					TimelineUtils.convertClip( MovieClip(mc), this, carrot );
					timeline = carrot.get( Timeline );
					timeline.looped = false;
					carrot.add( carrotComp ); 
				}
				
				for ( var k:int = 0; k < 6; k ++ )
				{ 
					sprite = new Sprite();
					sprite = Sprite( super._hitContainer[ "sCarrot" + ( k + 1 )]);
					sprite.visible = false;
				}
			}
		}
				
		private function hideCarrots( ):void
		{
			var sprite:Sprite;
			for ( var j:int = 0; j < 6; j ++ )
			{ 
				sprite = new Sprite();
				sprite = Sprite( super._hitContainer[ "sCarrot" + ( j + 1 )]);
				sprite.visible = false;
			}
		}
		
		private function setupButterflies():void 
		{
			var butterfly:Entity;
			var spatial:Spatial;
			var tween:Tween = new Tween();
			
			for ( var i:int = 0; i < 2; i ++ )
			{
				butterfly = EntityUtils.createMovingEntity( this, super._hitContainer[ "butterfly" + ( i + 1 )]);
				spatial = butterfly.get( Spatial );
				butterfly.add( tween ).add( new OriginPoint(spatial.x, spatial.y)).add( new SpatialAddition() );
				
				moveButterfly( butterfly );
			}
		}
		
		private function hideButterflies( ):void 
		{
			var butterfly:Entity;
			var display:Display;
			for ( var i:int = 0; i < 2; i ++ )
			{
				butterfly = EntityUtils.createSpatialEntity( this, super._hitContainer[ "butterfly" + ( i + 1 )]);
				display = butterfly.get( Display );
				display.visible = false;
			}
		}
		
		private function moveButterfly( butterfly:Entity ):void 
		{
			var spatial:Spatial = butterfly.get( Spatial );
			var motion:Motion = butterfly.get( Motion );
			var start:OriginPoint = butterfly.get( OriginPoint );
			var wave:WaveMotion = new WaveMotion();
			wave.add( new WaveMotionData( "x", Math.random() * 10, Math.random() / 10 ));
			wave.add( new WaveMotionData( "y", Math.random() * 10, Math.random() / 10 ));
			
			var goalX:Number;
			var goalY:Number;
			var duration:Number; 
			
			goalX = ( Math.random() * 200 ) + start.x - 100;
			goalY = ( Math.random() * 200 ) + start.y - 100;
		
			duration = ( Math.random() * 3 ) + 8;
			
			butterfly.remove(WaveMotion);
			butterfly.add( wave );
			var tween:Tween = butterfly.get( Tween );
			
			tween.to( spatial, duration, { x: goalX,     
				y: goalY, 
				ease:Sine.easeInOut,
				onComplete: moveButterfly,
				onCompleteParams:[ butterfly ]}); 	
		}
		
		private function setupLeaves():void
		{
			var leaf:Entity;
			var start:Point;
			var spatial:Spatial;
			var rotation:Number;
			_leaves = new Vector.<Entity>;
			
			for ( var i:int = 0; i < 3; i ++ )
			{
				leaf = EntityUtils.createMovingEntity( this, super._hitContainer[ "leaf" + ( i + 1 )]);
				spatial = leaf.get( Spatial );
				rotation = spatial.rotation;
				
				start = new Point( spatial.x, spatial.y );
				leaf.add(new OriginPoint(start.x, start.y, rotation));
				
				_leaves.push( leaf );
			}
			
			dropLeaf();
		}
		
		private function dropLeaf( ):void 
		{
			var number:int = Math.round( Math.random() * 2 );
			var leaf:Entity = _leaves[ number ];
			var motion:Motion = leaf.get( Motion );
			var spatial:Spatial = leaf.get( Spatial );
		//	var spatialAddition:SpatialAddition = new SpatialAddition(); 

			motion.acceleration.y = 12;
			motion.maxVelocity = new Point( 5, 40 );
			
			var wave:WaveMotion = new WaveMotion();
			
			wave.add( new WaveMotionData( "x", 15, .05 ));
			wave.add( new WaveMotionData( "rotation", -30, .05 ));
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 1074;
			threshold.entered.addOnce( Command.create( leafWait, leaf ));
			leaf.add( threshold ).add( new SpatialAddition() ).add( wave );
		}
		
		private function leafWait( leaf:Entity ):void
		{
			var motion:Motion = leaf.get( Motion );
			motion.velocity.y = 0;
			motion.acceleration.y = 0;
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 0;
			
			var tween:Tween = new Tween();
			var display:Display = leaf.get( Display ); 
			
			tween.to( display, 3, { alpha : 0 } );
			
			leaf.remove( WaveMotion );
			leaf.add( tween );
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, Command.create( resetLeaf, leaf )));
		}
		
		private function resetLeaf( leaf:Entity ):void
		{
			leaf.remove( SpatialAddition );
			var spatial:Spatial = leaf.get( Spatial );
			var origin:OriginPoint = leaf.get( OriginPoint );
			
			spatial.x = origin.x;
			spatial.y = origin.y;
			spatial.rotation = origin.rotation;
			
			var tween:Tween = leaf.get( Tween );
			var display:Display = leaf.get( Display ); 
			tween.to( display, 1, { alpha : 100 } );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, dropLeaf ));
		}
		
		private var _events:CarrotEvents;
		private var _carrots:Vector.<Entity>;
		private var _leaves:Vector.<Entity>;
	}
}