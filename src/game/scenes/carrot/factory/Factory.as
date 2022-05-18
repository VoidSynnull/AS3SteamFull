package game.scenes.carrot.factory
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.TransportGroup;
	
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.motion.Edge;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Crowbar;
	import game.data.game.GameEvent;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.carrot.sewer.Sewer;
	import game.components.entity.OriginPoint;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Factory extends PlatformerGameScene
	{
		public function Factory()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/factory/";
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
			
			_events = super.events as CarrotEvents;
			
			setupGrate();
			setupBarrels();
			setupLeaf();

			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player );
			}
		}

		override public function destroy():void
		{
			_leaf = null;
			_grate = null;
			_events = null;
			if(_oldDoorClicked != null)
			{
				_oldDoorClicked.removeAll();
			}
			this.transportGroup = null;
			
			super.destroy();
		}
		
		private function setupGrate():void
		{
			var sewerDoor:Entity = super.getEntityById("doorSewer");
			var sewerDoorInteraction:SceneInteraction = sewerDoor.get(SceneInteraction);
			var sewerDoorInt:Interaction = sewerDoor.get(Interaction);
			sewerDoorInteraction.offsetX = 0;
			//Spatial(sewerDoor.get(Spatial)).x += 60;

			if ( super.shellApi.checkEvent(_events.SEWER_OPENED) )
			{
				super._hitContainer["grate"].visible = false;
			}
			else
			{
				_grate = EntityUtils.createMovingEntity( this, super._hitContainer["grate"] );
				_grate.add( new Id( "grate" ));
				var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
				audioGroup.addAudioToEntity(_grate);
				
				// Remove standard door listeners and add custum listener, offset door target
				_oldDoorClicked = sewerDoorInt.click;
				sewerDoorInt.click = new Signal();
				sewerDoorInt.click.add(doorReached);
			}
		}
		
		private function setupBarrels():void
		{
			var parent:Entity = super.getEntityById("water");
			parent.remove(Sleep);
			parent.sleeping = false;
			
			setupBarrel(1, 0, parent);
			setupBarrel(2, Math.PI / 4, parent);
			setupBarrel(3, Math.PI / 2, parent);

			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			super.addSystem( new SceneObjectMotionSystem() );
		}
		
		private function setupBarrel(id:int, angle:Number, parent:Entity):void
		{
			var spatialAddition:SpatialAddition = new SpatialAddition();	// this is shared by both barrel Entities 
			
			// barrel display
			var barrelVisual:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["barrel" + id]);//super.getEntityById("barrel" + id);
			barrelVisual.remove(Sleep);
			barrelVisual.sleeping = false;
			barrelVisual.add( spatialAddition );
			var display:Display = barrelVisual.get(Display);
			
			// barrel hit
			var barrelHit:Entity = super.getEntityById("barrelHit" + id);
			barrelHit.remove(Sleep);
			barrelHit.sleeping = false;
			//barrelHit.add( new Motion() );
			var edge:Edge = new Edge();
			edge.unscaled = display.displayObject.getBounds(display.displayObject);
			barrelHit.add( edge );

			/*var waterCollider:WaterCollider = new WaterCollider();
			waterCollider.density = .4;
			waterCollider.dampener = .2;
			barrelHit.add( waterCollider );	
			barrelHit.add( new SceneObjectMotion() );
			*/
			// add wave motion
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.data.push(new WaveMotionData("rotation", 2, 0.05, "sin", angle));
			waveMotion.data.push(new WaveMotionData("y", 3, 0.02, "sin", 0.5 * id));
			barrelHit.add(waveMotion);
			barrelHit.add(spatialAddition);
			// the barrels should stop updating if the 'parent' (the water they're sitting in) is sleeping.  This prevents them from falling through it.
			
			EntityUtils.addParentChild(barrelVisual, barrelHit);
		//	EntityUtils.addParentChild(barrelHit, parent);
			
			//DisplayUtils.cacheAsBitmap( display.displayObject );
		}
		
		private function doorReached(/*entity:Entity, */door:Entity):void
		{			
			var doorSpatial:Spatial = door.get(Spatial);
			
			if(!super.shellApi.checkEvent(GameEvent.GOT_ITEM + _events.CROWBAR))
			{
				super.shellApi.triggerEvent(_events.SEWER_ATTEMPT_OPEN);
			}
			else if (!super.shellApi.checkEvent(_events.SEWER_OPENED))
			{
				var path:Vector.<Point> = new Vector.<Point>;
				//path.push( new Point( 3135, 1665 ));
				path.push( new Point( 3100, 1490 ));
				path.push( new Point( 3045, 1545 ));
				CharUtils.followPath( super.shellApi.player, path, openSewer, false, false, new Point( 25, 25 ) ).setDirectionOnReached( CharUtils.DIRECTION_RIGHT );

			}
			else
			{
				Door(door.get(Door)).open = true;
			}
		}
		
		public function openSewer( character:Entity = null ):void
		{
			// TODO :: Revisit this, might be a cleaner way to handle this with teh states
			CharUtils.setState( super.player, CharacterState.STAND );
			SceneUtil.lockInput(this, true, false);
			CharUtils.lockControls(super.player, true, true);
			CharUtils.getTimeline( super.player ).labelReached.add( onCrowbarLabels );	// listen for trigger & end
			CharUtils.setAnim( super.player, Crowbar );									// play crowbar aniamtion
			//MotionControl( super.player.get( MotionControl ) ).lockInput = true;				// lock controls
		}
		
		public function onCrowbarLabels( label:String ):void
		{
			if ( label == Animation.LABEL_BEGINNING )
			{
				super.shellApi.triggerEvent( _events.GRATE_OPENNING );
			}
			else if ( label == Animation.LABEL_TRIGGER )			// open crate
			{
				var motion:Motion = _grate.get( Motion );	// TODO :: make sure this is having sleep applied once it is off screen
				motion.velocity.x += 250;
				motion.acceleration.y = 750;
				super.shellApi.triggerEvent( _events.GRATE_OPEN );
				
				motion.friction = new Point( 1.5, 0 );
			}
			else if ( label == Animation.LABEL_ENDING )	
			{
				//MotionControl( super.player.get( MotionControl)).lockInput = false;	//return control
				/*
				CharUtils.getTimeline( super.player ).labelReached.remove(onCrowbarLabels);
				super.shellApi.completeEvent( _events.SEWER_OPENED );			// complete 'sewerOpen" event, sewer will be open from now on
				SceneUtil.lockInput(this, false, false);
				CharUtils.lockControls(super.player, false, false);
				var sewerDoor:Entity = super.getEntityById("doorSewer");
				var sewerDoorInt:Interaction = sewerDoor.get(Interaction);
				sewerDoorInt.click.removeAll();
				sewerDoorInt.click = _oldDoorClicked;
				*/
				super.shellApi.completeEvent( _events.SEWER_OPENED );
				super.shellApi.loadScene( Sewer );
			}
		}
		
		private function setupLeaf():void
		{
			var start:Point;
			var spatial:Spatial;
			var rotation:Number;
			
			_leaf = EntityUtils.createMovingEntity( this, super._hitContainer[ "leaf" ]);
			spatial = _leaf.get( Spatial );
			rotation = spatial.rotation;
			
			start = new Point( spatial.x, spatial.y );
			_leaf.add(new OriginPoint(spatial.x, spatial.y, rotation));
			
			dropLeaf();
		}
		
		private function dropLeaf():void 
		{
			var motion:Motion = _leaf.get( Motion );
			var spatial:Spatial = _leaf.get( Spatial );
			var spatialAddition:SpatialAddition = new SpatialAddition(); 

			motion.acceleration.y = 12;
			motion.maxVelocity = new Point( 5, 40 );
			
			var wave:WaveMotion = new WaveMotion();
			
			wave.add( new WaveMotionData( "x", 15, .05 ));
			wave.add( new WaveMotionData( "rotation", -30, .05 ));
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 1596;
			threshold.entered.addOnce( leafWait );
			_leaf.add( threshold ).add( spatialAddition ).add( wave );
		}
		
		private function leafWait():void
		{
			var motion:Motion = _leaf.get( Motion );
			motion.velocity.y = 0;
			motion.acceleration.y = 0;
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 0;
			
			var tween:Tween = new Tween();
			var display:Display = _leaf.get( Display ); 
			
			tween.to( display, 3, { alpha : 0 } );
			
			_leaf.remove( WaveMotion );
			_leaf.add( tween );
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, resetLeaf ));
		}
		
		private function resetLeaf():void
		{
			_leaf.remove( SpatialAddition );
			var spatial:Spatial = _leaf.get( Spatial );
			var display:Display = _leaf.get( Display );
			var origin:OriginPoint = _leaf.get( OriginPoint );
			
			spatial.x = origin.x;
			spatial.y = origin.y;
			spatial.rotation = origin.rotation;
			
			var tween:Tween = _leaf.get( Tween );
			tween.to( display, 1, { alpha : 100 } );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, dropLeaf ));
		}
		
		private var _leaf:Entity;
		private var _grate:Entity;
		private var _events:CarrotEvents;
		private var _oldDoorClicked:Signal;
		
		private var transportGroup:TransportGroup;
	}
}