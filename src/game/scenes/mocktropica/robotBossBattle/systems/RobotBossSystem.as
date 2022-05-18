package game.scenes.mocktropica.robotBossBattle.systems {
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.profiler.showRedrawRegions;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.Node;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.data.TimedEvent;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.robotBossBattle.classes.State;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.components.RobotBoss;
	import game.scenes.mocktropica.robotBossBattle.components.RobotMissile;
	import game.scenes.mocktropica.robotBossBattle.components.StateMachine;
	import game.scenes.mocktropica.robotBossBattle.components.Track3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.nodes.CoinShotNode;
	import game.scenes.mocktropica.robotBossBattle.nodes.RobotBossNode;
	import game.scenes.mocktropica.robotBossBattle.nodes.RobotPlayerNode;
	import game.util.SceneUtil;

	/**
	 * Note: because states can change either from checks in the update() loop or due to event handlers,
	 * the parameter lists of functions that start new states vary widely from state to state.
	 */
	public class RobotBossSystem extends System {

		/**
		 * onBossDestroyed( entity )
		 */
		public var onBossDestroyed:Function;

		private var bossList:NodeList;

		/**
		 * missileList can be searched to find player missiles and attempt to dodge them.
		 */
		private var coinList:NodeList;

		/**
		 * Might need the player list to prevent the boss from firing at empty sections of the screen.
		 * Won't support this functionality right off.
		 */
		private var playerList:NodeList;

		/**
		 * Need camera information to get scene area -- which doesn't seem to be accessible from the scene itself?
		 */
		private var camera:CameraSystem;

		public function RobotBossSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:RobotBossNode = this.bossList.head; node; node = node.next ) {

				// tilt boss rotation based on velocity-X.
				node.spatial.rotation = node.motion.velocity.x*30/node.motion.maxSpeed;

				node.boss.timer -= time;

				if ( node.zdepth.z > RobotBoss.Z_MAX ) {
					node.zdepth.z = RobotBoss.Z_MAX;
				} else if ( node.zdepth.z < RobotBoss.Z_MIN ) {
					node.zdepth.z = RobotBoss.Z_MIN;
				} // end-if.

				switch( node.machine.currentState.id ) {

					case RobotBoss.IDLE:
						node.boss.dodgeTimer -= time;
						this.doIdle( node );
						break;
					case RobotBoss.DODGE:
						// the boss can only be shown to die in states when his animation basically matches the death state.
						// that rules out dying while firing missiles or carrying a boulder.
						if ( node.life.alive == false ) {
							this.bossDied( node );
						}
						break;
					case RobotBoss.BOULDER_IDLE:
						this.doBoulderIdle( node );
						break;
					case RobotBoss.THROW:
						this.checkBoulderFrame( node );
						break;
					case RobotBoss.FIRE_MISSILE:
						this.checkMissileFrame( node );
						break;

					default:

				} // end-switch.

			} // end for-loop.

		} //

		/**
		 * Might move this to robotBossSystem. Not very important either way.
		 * 
		 * In a lot of ways this function isn't necessary; since at this point all states
		 * are changed manually anyway. Still...
		 */
		private function robotStateChanged( entity:Entity, newState:State ):void {

			var robot:RobotBoss = entity.get( RobotBoss );

			// get the display for the new state.
			var newDisplay:MovieClip = robot.getStateDisplay( newState.id );
			if ( newDisplay != null ) {

				this.swapDisplay( entity.get( Display ), newDisplay );

				var tl:VariableTimeline = entity.get( VariableTimeline );
				tl.resetWith( newDisplay );
				tl.gotoAndPlay( 1 );

			} // end-if.

			switch ( newState.id ) {

				case RobotBoss.IDLE:
					robot.timer = 3;
					break;

				case RobotBoss.BOULDER_IDLE:
					super.group.shellApi.triggerEvent("boss_has_rock");	
					robot.timer = 5;
					break;

				case RobotBoss.DODGE:
					super.group.shellApi.triggerEvent("boss_flying");	
					// Don't need to do anything. The dodge direction was set when we checked the missiles.
					break;

//				case RobotBoss.FETCH_BOULDER:
//					break;

				case RobotBoss.FIRE_MISSILE:
					super.group.shellApi.triggerEvent("launch_fists");	
					tl.onTimelineEnd.addOnce( this.fireMissileDone );
					break;

				case RobotBoss.THROW:
					super.group.shellApi.triggerEvent("throw_rock");
					tl.onTimelineEnd.addOnce( this.throwBoulderDone );
					break;

				case RobotBoss.KILLED:
					SceneUtil.setCameraTarget( this.group as Scene, entity );
					// listen for the end of the timeline.
					SceneUtil.addTimedEvent(group, new TimedEvent(0.4,8,Command.create(group.shellApi.triggerEvent,"boss_explodes")));
					//group.shellApi.triggerEvent("boss_explodes");
					tl.onTimelineEnd.addOnce( this.robotKilledDone );
					break;

				default:

			} //

		} //

		private function checkBoulderFrame( node:RobotBossNode ):void {

			if ( ( node.display.displayObject as MovieClip ).currentFrameLabel != "throwBoulder" ) {
				return;
			}

			var robotClip:MovieClip = node.display.displayObject as MovieClip;
			var src:MovieClip = robotClip.boulder;

			var boulderEntity:Entity = node.boss.boulder;
			var spatial:Spatial = boulderEntity.get( Spatial ) as Spatial;

			var p:Point = robotClip.parent.globalToLocal( src.localToGlobal( new Point() ) );

			spatial.x = p.x;
			spatial.y = p.y;
			spatial.rotation = robotClip.rotation + src.rotation;

			( boulderEntity.get( ZDepthNumber ) as ZDepthNumber).z = node.zdepth.z - 2;
			( boulderEntity.get( Display ) as Display ).visible = true;
			( boulderEntity.get( Sleep ) as Sleep ).sleeping = false;

			( boulderEntity.get( Motion3D ) as Motion3D ).velocity.z = -RobotMissile.MISSILE_SPEED;

		} //

		private function checkMissileFrame( node:RobotBossNode ):void {

			if ( ( node.display.displayObject as MovieClip ).currentFrameLabel != "fireHands" ) {
				return;
			}

			node.tracking.active = false;
			node.target.continuous = false;
			this.fireHandMissiles( node.display.displayObject as MovieClip, node.boss.leftHand, node.boss.rightHand, node.zdepth.z-2 );

		} //

		/**
		 * Match the missile positions to the missile clips within the robot clip, so they appear to be coming from the correct
		 * location. No idea how this will work out.
		 */
		private function fireHandMissiles( robotClip:MovieClip, leftMissile:Entity, rightMissile:Entity, z:Number ):void {

			var src:MovieClip = robotClip.leftHand;
			var spatial:Spatial = leftMissile.get( Spatial ) as Spatial;

			var p:Point = robotClip.parent.globalToLocal( src.localToGlobal( new Point() ) );

			spatial.x = p.x;
			spatial.y = p.y;
			//spatial.rotation = src.rotation;

			//trace( "HAND LOC: " + spatial.x + "," + spatial.y );

			( leftMissile.get( ZDepthNumber ) as ZDepthNumber).z = z;

			( leftMissile.get( Display ) as Display ).visible = true;
			( leftMissile.get( Sleep ) as Sleep ).sleeping = false;
			( leftMissile.get( Motion3D ) as Motion3D ).velocity.z = -RobotMissile.MISSILE_SPEED;


			// right hand.
			src = robotClip.rightHand;

			p.setTo( 0, 0 );
			p = robotClip.parent.globalToLocal( src.localToGlobal( p ) );

			spatial = rightMissile.get( Spatial ) as Spatial;
			spatial.x = p.x;
			spatial.y = p.y;
			//spatial.rotation = src.rotation;

			( rightMissile.get( ZDepthNumber ) as ZDepthNumber).z = z;

			( rightMissile.get( Display ) as Display ).visible = true;
			( rightMissile.get( Sleep ) as Sleep ).sleeping = false;
			( rightMissile.get( Motion3D ) as Motion3D ).velocity.z = -RobotMissile.MISSILE_SPEED;

		} //

		/**
		 * Stupid robot reached some stupid position that he was trying to reach
		 * and now he's gotta stupid do something else stupid.
		 */
		/*private function onReachedTarget( robotEntity:Entity ):void {

			var robot:RobotBoss = robotEntity.get( RobotBoss );
			var machine:StateMachine = robotEntity.get( StateMachine );

			var state:State = machine.currentState;

			// change state or something?

		} //*/

		private function bossDied( node:RobotBossNode ):void {

			//node.target.active = false;
			node.target.setTarget( node.spatial.x, node.spatial.y, node.zdepth.z );
			node.machine.setState( RobotBoss.KILLED );

		} //

		/*private function randomMove( node:RobotBossNode ):void {

			var cam:CameraSystem = this.group.shellApi.camera;
			node.target.setTarget( Math.random()*cam.areaWidth, Math.random()*cam.areaHeight,
				RobotBoss.Z_MIN + Math.random()*( RobotBoss.Z_MAX - RobotBoss.Z_MIN ) );

		} //*/

		private function doIdle( node:RobotBossNode ):void {

			if ( node.life.alive == false ) {

				this.bossDied( node );

			} else if ( node.boss.dodgeTimer <= 0 && this.checkDodge( node ) ) {

			} else if ( node.boss.timer <= 0 ) {

				// pick an attack
				var r:Number = Math.random();
				if ( r < 0.60 ) {

					node.tracking.active = true;
					node.target.continuous = true;
					node.machine.setState( RobotBoss.FIRE_MISSILE );					

				} else {

					// fetch a boulder.
					this.startFetch( node );

				} // end-if.

			} //

		} //

		/**
		 * Wait til close enough to the player screen to hit player, or else til timer
		 * runs out, then throw the boudler.
		 */
		private function doBoulderIdle( node:RobotBossNode ):void {

			super.group.shellApi.triggerEvent("rocket_engines_01_loop");

			if ( node.boss.timer <= 0 ) {

				node.tracking.active = false;
				node.target.continuous = false;
				node.machine.setState( RobotBoss.THROW );

			} else {

				// check if close enough to the player to throw the boulder. god need a player node for this.. stupid.
				// maybe we can check against the current view center?
				// don't think this is the real center.
				var dx:Number = node.spatial.x - this.camera.center.x;
				var dy:Number = node.spatial.y - this.camera.center.y;

				if ( Math.abs( dx ) < 200 && Math.abs(dy) < 200 ) {
					node.tracking.active = false;
					node.target.continuous = false;
					node.machine.setState( RobotBoss.THROW );
				}

			} // end-if.

		} //

		private function checkDodge( node:RobotBossNode ):Boolean {

			var x:Number = node.spatial.x;
			var y:Number = node.spatial.y;

			var dx:Number, dy:Number;
			var missile:RobotMissile;

			for( var coinNode:CoinShotNode = this.coinList.head; coinNode; coinNode = coinNode.next ) {

				dx = x - coinNode.spatial.x;
				if ( Math.abs(dx) > node.hit.halfWidth ) {
					continue;
				}
				dy = y - coinNode.spatial.y;
				if ( Math.abs(dy) > node.hit.halfHeight ) {
					continue;
				}

				this.startDodge( node, dx );

				return true;

			} // end for-loop.

			return false;

		} //

		/**
		 * Begins a left/right dodge.
		 * 
		 * dx is the x-direction of the boss from the missile.
		 */
		private function startDodge( node:RobotBossNode, dx:Number ):void {

			node.machine.pushState( RobotBoss.DODGE );
			/**
			 * Don't try to dodge again for awhile.
			 */
			node.boss.dodgeTimer = 2;

			// pick a dodge direction.

			var target:MoveTarget3D = node.target;
			if ( dx < 0 ) {

				target.setTarget( Math.max( node.hit.halfWidth, node.spatial.x - 600 ), node.spatial.y, node.zdepth.z );

			} else {

				target.setTarget( Math.min( camera.areaWidth-node.hit.halfWidth, node.spatial.x + 600 ), node.spatial.y, node.zdepth.z );

			} // end-if.

			node.target.acceleration = node.boss.dodgeAcceleration;

			target.onReachedTarget.addOnce( this.dodgeComplete );

		} //

		private function dodgeComplete( e:Entity ):void {

			// restore old speeds/accelerations.
			( e.get( MoveTarget3D ) as MoveTarget3D ).acceleration = (e.get( RobotBoss ) as RobotBoss).moveAcceleration;

			// go back to the previous state.
			( e.get( StateMachine ) as StateMachine ).popState();

		} //

		/**
		 * Fly up offscreen to get the boulder.
		 */
		private function startFetch( node:RobotBossNode ):void {

			//trace( "START FETCH" );

			node.target.setTarget( node.spatial.x, -3*node.spatial.height, node.zdepth.z );
			node.target.onReachedTarget.addOnce( this.fetchOffscreen );

			node.machine.setState( RobotBoss.FETCH_BOULDER );

		} //

		/**
		 * robot went offscreen to get the boulder. Now play the animation that crosses over the mountains.
		 */
		private function fetchOffscreen( e:Entity ):void {

			var fetchAnimation:Entity = ( e.get(RobotBoss) as RobotBoss ).fetchAnimation;
			var display:Display = fetchAnimation.get( Display );
			display.visible = true;

			var tl:VariableTimeline = fetchAnimation.get( VariableTimeline );
			tl.gotoAndPlay( 1 );

			super.group.shellApi.triggerEvent("boss_dash");

		} //

		/**
		 * The weird parameter list is due to the convoluted way the fetch animation was included with the scene
		 * + the convoluted way events are handled in an entity system.
		 * 
		 * Once the fetch is done, the robot needs to come back onscreen.
		 */
		private function fetchAnimationDone( animationEntity:Entity, tl:VariableTimeline, robotEntity:Entity ):void {

			//( robotEntity.get( StateMachine ) as StateMachine ).setState( RobotBoss.FETCH_RETURN );

			var clip:MovieClip = (robotEntity.get(RobotBoss) as RobotBoss).getStateDisplay( RobotBoss.BOULDER_IDLE );
			this.swapDisplay( robotEntity.get( Display ), clip );

			( robotEntity.get( Motion3D ) as Motion3D ).zeroMotion();

			var tl2:VariableTimeline = robotEntity.get( VariableTimeline );
			tl2.resetWith( clip );
			tl2.gotoAndPlay( 1 );

			var display:Display = animationEntity.get( Display );
			display.visible = false;

			// Now robot comes back onscreen.
			var sp:Spatial = robotEntity.get( Spatial );
			var target:MoveTarget3D = robotEntity.get( MoveTarget3D );

			// come up from bottom of the screen.
			sp.y = this.camera.areaHeight + 2*sp.height;

			target.setTarget( sp.x, this.camera.areaHeight/2, RobotBoss.Z_MIN + Math.random()*(RobotBoss.Z_MAX-RobotBoss.Z_MIN) );
			target.onReachedTarget.addOnce( this.fetchOnscreen );

		} //

		/**
		 * robot came back with the boulder.
		 */
		private function fetchOnscreen( e:Entity ):void {

			( e.get( StateMachine ) as StateMachine ).setState( RobotBoss.BOULDER_IDLE );
			( e.get( Track3D ) as Track3D ).active = true;
			( e.get( MoveTarget3D ) as MoveTarget3D ).continuous = true;

		} //

		private function fireMissileDone( entity:Entity, tl:VariableTimeline ):void {
			var machine:StateMachine = entity.get( StateMachine );
			machine.setState( RobotBoss.IDLE );

		} //

		/**
		 * Change state to idle.
		 */
		private function throwBoulderDone( e:Entity, tl:VariableTimeline ):void {
			( e.get( StateMachine ) as StateMachine ).setState( RobotBoss.IDLE );

		} //

		private function swapDisplay( display:Display, newDisplay:DisplayObject ):void {

			if ( display.displayObject != newDisplay ) {

				var depth:int = display.container.getChildIndex( display.displayObject );
				display.container.removeChild( display.displayObject );

				display.displayObject = newDisplay;
				display.container.addChildAt( newDisplay, depth );
				//display.invalidate = true;
			}

		} //

		/**
		 * Robot is dead. DEAD.
		 */
		private function robotKilledDone( entity:Entity, tl:VariableTimeline ):void {

			tl.playing = false;
			( entity.get( Display ) as Display ).visible = false;

			this.onBossDestroyed( entity );

		} //

		private function nodeAdded( node:RobotBossNode ):void {

			node.machine.onStateChanged.add( this.robotStateChanged );
			//node.target.onReachedTarget.add( this.onReachedTarget );

			node.machine.setState( RobotBoss.IDLE );

			node.target.acceleration = node.boss.moveAcceleration;
			node.target.decceleration = node.boss.decceleration;
			node.motion.maxSpeed = node.boss.moveSpeed;

			/**
			 * Intialize callbacks for the fetch animation stuff.
			 */
			var entity:Entity = node.boss.fetchAnimation;

			var display:Display = entity.get( Display );
			display.visible = false;

			var vt:VariableTimeline = new VariableTimeline();
			vt.loop = false;
			vt.gotoAndStop( 1 );
			vt.onTimelineEnd.add( Command.create(this.fetchAnimationDone, node.entity) );
			entity.add( vt, VariableTimeline );

			node.spatial._updateHeight = node.spatial._updateWidth = false;

		} //

		private function nodeRemoved( node:RobotBossNode ):void {

			node.boss.boulder = node.boss.leftHand = node.boss.rightHand = null;

			node.machine.onStateChanged.removeAll();
			node.target.onReachedTarget.removeAll();

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.bossList = systemManager.getNodeList( RobotBossNode );

			for( var node:Node = this.bossList.head; node; node = node.next ) {
				this.nodeAdded( node as RobotBossNode );
			} //

			this.bossList.nodeAdded.add( this.nodeAdded );

			this.coinList = systemManager.getNodeList( CoinShotNode );
			this.playerList = systemManager.getNodeList( RobotPlayerNode );

			this.camera = systemManager.getSystem( CameraSystem ) as CameraSystem;

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.coinList = null;
			this.playerList = null;

			this.bossList.nodeAdded.removeAll();
			this.bossList = null;

		} //

	} // End RobotBossSystem

} // End package