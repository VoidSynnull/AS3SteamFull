package game.scenes.lands.shared.monsters.systems {
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandClock;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.components.SimpleTarget;
	import game.scenes.lands.shared.monsters.components.PixieMonster;
	import game.scenes.lands.shared.monsters.nodes.PixieMonsterNode;
	
	public class PixieMonsterSystem extends System {
		
		private var pixies:NodeList;
		
		private var tileHits:TileBitmapHits;
		private var player:Entity;
		
		private var clock:LandClock;
		
		public function PixieMonsterSystem() {

			super();

		} //
		
		override public function update( time:Number ):void {
			
			var pixie:PixieMonster;

			if ( this.player.sleeping ) {
				return;
			}

			if ( this.pixies.head == null ) {

				if ( !this.clock.isNight() ) {
					// no longer night-time, so no more pixies should spawn.
					this.group.removeSystem( this, true );
				}

				return;

			} //
			
			for( var node:PixieMonsterNode = this.pixies.head; node; node = node.next ) {
				
				pixie = node.pixie;
				if ( ++pixie.waitThink < 10 ) {
					continue;
				}
				pixie.waitThink = 0;

				if ( pixie.blocked ) {
					
					// pixie can't move right now. try a random retarget.
					if ( Math.random() < 0.1 ) {
						this.forceTarget( node, node.spatial.x - 64 + 128*Math.random(), node.spatial.y - 32*Math.random() );
					}
					continue;

				} else if ( pixie.state != pixie.LEAVING && !this.clock.isNight() ) {
					this.beginLeaveScene( node );
					continue;
				}

				switch ( pixie.state ) {
					
					case pixie.WANDER:
						this.doWander( node );
						break;
					case pixie.ATTACK:
						this.doAttackPlayer( node );
						break;
					case pixie.FLEE:
						this.doFleePlayer( node );
						break;
					case pixie.LEAVING:

						if ( node.spatial.y < -10 ) {
							this.group.removeEntity( node.entity, true );
						} else {
							node.target.targetY = -100;
						} //
						break;
					
				} // switch
				
			} // for
			
		} // update()
		
		private function doFleePlayer( node:PixieMonsterNode ):void {
			
			var pSpatial:Spatial = player.get( Spatial );
			var sp:Spatial = node.spatial;
			
			var dx:Number = pSpatial.x - sp.x;
			var dy:Number = pSpatial.y - sp.y;
			
			var d:Number = dx*dx + dy*dy;
			
			if ( d > (900*900) ) {
				
				// far enough away. revert to wander.
				//trace( "FLEE COMPLETE" );
				( node.display.displayObject as MovieClip ).pixie.gotoAndStop( 1 );
				node.pixie.state = node.pixie.WANDER;
				
			} else {
				
				d = Math.sqrt( d );
				
				if ( d < 1 ) {
					// not technically correct but close enough for targetting.
					dx = Math.random();
					dy = 1 - dx;
					d = 1;
				} else {
					// run directly away from the player.
					dx /= d;
					dy /= d;
				}
				
				this.tryRetarget( node, sp.x - 400*dx, sp.y-400*dy );
				
			} //
			
		} //
		
		private function doAttackPlayer( node:PixieMonsterNode ):void {
			
			var pSpatial:Spatial = player.get( Spatial );
			var sp:Spatial = node.spatial;
			
			var d1:Number = pSpatial.x - sp.x;
			var d2:Number = pSpatial.y - sp.y;
			d1 = d1*d1 + d2*d2;
			
			if ( d1 > ( 500*500 ) ) {
				
				// too far from player. revert to wander mode.
				node.pixie.state = node.pixie.WANDER;
				
			} else if ( d1 < (30*30) ) {
				
				// basically hitting the player. steal poptanium and run away.
				this.stealPoptanium( node );
				
			} else {

				// normal target player.
				//node.target.targetX = pSpatial.x;
				//node.target.targetY = pSpatial.y;
				this.tryRetarget( node, pSpatial.x, pSpatial.y );

			} //
			
		} //
		
		private function onLightningStrike( entity:Entity, strike:LightningStrike ):void {
			
			var pixie:PixieMonster = entity.get( PixieMonster );
			
			// the clip inside the movie clip is called pixie.
			var clip:MovieClip = ( ( entity.get( Display ) as Display ).displayObject as MovieClip ).pixie;
			
			// this is an incredibly stupid way to check if the pixie is carrying poptanium.
			// seriously justin, just put it in the pixie component.
			if ( clip.currentFrame == 2 ) {
				
				// drop the poptanium.
				clip.gotoAndStop( 1 );
				
				var sp:Spatial = entity.get( Spatial );
				( this.group as LandGroup ).spawnPoptanium( sp.x, sp.y, 10 );
				
			} //
			
			// push the pixie back.
			var target:SimpleTarget = entity.get( SimpleTarget );
			if ( target ) {
				target.vx += strike.strike_dx * 12;
				target.vy += strike.strike_dy * 12;
			}
			
			// no more hits on this pixie.
			( entity.get( LightningTarget ) as LightningTarget ).enabled = false;
			
			// run away and never come back.
			pixie.state = pixie.LEAVING;
			target.targetY = -100;
			
		} //
		
		/**
		 * steal poptanium from the player.
		 */
		private function stealPoptanium( node:PixieMonsterNode ):void {
			
			( node.display.displayObject as MovieClip ).pixie.gotoAndStop( 2 );
			node.pixie.state = node.pixie.FLEE;
			
			(this.group as LandGroup ).losePoptanium( node.spatial.x, node.spatial.y, 10 );
			
		} //
		
		private function doWander( node:PixieMonsterNode ):void {
			
			var pSpatial:Spatial = player.get( Spatial );
			var sp:Spatial = node.spatial;
			
			var d1:Number = pSpatial.x - sp.x;
			var d2:Number = pSpatial.y - sp.y;
			
			if ( (d1*d1 + d2*d2) < 500*500 ) {
				
				// pixie attack player.
				node.pixie.state = node.pixie.ATTACK;
				
			} else if ( Math.random() < 0.1 ) {
				
				this.tryRetarget( node, sp.x - 400 + 800, sp.y - 400 + 800*Math.random() );
				
			} //
			
		} //

		/*private function randomTarget( node:PixieMonsterNode ):void {
		} //*/

		private function forceTarget( node:PixieMonsterNode, tX:Number, tY:Number ):void {

			node.target.targetX = tX;
			node.target.targetY = tY;

			// still need to check blocked status so you can eventually break out of the blocked condition.
			var blocked:Boolean = this.tileHits.lineTest( node.spatial.x, node.spatial.y, new Point( tX, tY ) );
			if ( !blocked ) {
				node.pixie.blocked = false;
			}

		} //

		/**
		 * tries to retarget, but retargets to the first blocked point.
		 */
		private function tryRetarget( node:PixieMonsterNode, tX:Number, tY:Number ):void {
			
			var targetPt:Point = new Point( tX, tY );
			
			var blocked:Boolean = this.tileHits.lineTest( node.spatial.x, node.spatial.y, targetPt );

			if ( blocked ) {

				if ( targetPt.x == node.spatial.x && targetPt.y == node.spatial.y ) {
					node.pixie.blocked = true;
					return;
				}

			} //

			node.target.targetX = targetPt.x;
			node.target.targetY = targetPt.y;

		} //

		private function beginLeaveScene( node:PixieMonsterNode ):void {

			//node.target.targetY = -100;
			this.tryRetarget( node, node.spatial.x, -100 );
			node.pixie.state = node.pixie.LEAVING;

		} //

		private function onPixieAdded( node:PixieMonsterNode ):void {
			
			//var pixieClip:MovieClip = ( node.display.displayObject as MovieClip ).pixie;
			//pixieClip.gotoAndStop( 1 );
			//pixieClip.mouseChildren = false;
			
			( node.display.displayObject as MovieClip ).pixie.gotoAndStop( 1 );
			
			// when the user hits the pixie with lightning.
			node.lightningTarget.strikeFunc = this.onLightningStrike;
			
		} //
		
		/*private function nodeRemoved( node:PixieMonsterNode ):void {
		} //*/
		
		override public function addToEngine( systemManager:Engine ):void {
			
			this.pixies = systemManager.getNodeList( PixieMonsterNode );
			this.pixies.nodeAdded.add( this.onPixieAdded );
			//this.pixies.nodeRemoved.add( this.nodeRemoved );
			
			var landGroup:LandGroup = this.group as LandGroup;
			
			var gd:LandGameData = landGroup.gameData;
			this.tileHits = gd.tileHits;
			
			this.clock = gd.clock;
			this.player = landGroup.getPlayer();
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.tileHits = null;
			
			this.pixies.nodeAdded.remove( this.onPixieAdded );
			//this.pixies.nodeRemoved.remove( this.nodeRemoved );
			this.pixies = null;
			
		} //
		
	} // class
	
} // package