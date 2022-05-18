package game.scenes.lands.shared.monsters.systems {
	
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.monsters.MonsterFollow;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.monsters.nodes.MonsterFollowNode;

	
	public class MonsterFollowSystem extends System {
		
		private var monsterList:NodeList;
		
		/**
		 * tells what spaces are walkable.
		 */
		private var tileHits:TileBitmapHits;
		
		private var landData:LandGameData;
		
		/**
		 * onMonsterArrive( MonsterFollowNode )
		 */
		//private var onMonsterArrive:Signal;
		
		public function MonsterFollowSystem( landGroup:LandGroup ) {
			
			super();
			
			//landGroup.onBiomeChanged.add( this.biomeChanged );
			//landGroup.onPreLeaveScene.add( this.checkMultiScene );
			
			this.landData = landGroup.gameData;
			this.tileHits = this.landData.tileHits;
			//this.tileMap = this.landData.tileMaps["terrain"];
			
			//this.onMonsterArrive = new Signal( MonsterFollowNode );
			
		} //
		
		override public function update( time:Number ):void {
			
			var follow:MonsterFollow;
			var tSpatial:Spatial;
			var spatial:Spatial;
			var dx:int, dy:int, d2:Number;
			
			// deltas to current target.
			var destPoint:Point;
			
			for( var node:MonsterFollowNode = this.monsterList.head; node; node = node.next ) {
				
				if ( node.entity.sleeping ) {
					continue;
				}
				follow = node.targetInfo;
				if ( follow.targetMode == 0 ) {
					node.entity.remove( MonsterFollow );
					node.monster.action = LandMonster.NONE;
					continue;
				}
				
				/**
				 * check too far from target.
				 */
				/*follow._distCheckTime -= time;
				if ( follow._distCheckTime <= 0 ) {
				continue;
				}*/
				
				if ( follow.targetMode == follow.TARGET_ENTITY ) {
					destPoint = this.targetEntity( follow );
				} else if ( follow.targetMode == follow.TARGET_TILE ) {
					destPoint = this.targetTile( follow );
				}
				if ( destPoint == null ) {
					continue;
				}
				
				
				spatial = node.spatial;
				dx = destPoint.x - spatial.x;
				dy = destPoint.y - spatial.y;
				d2 = dx*dx + dy*dy;
				
				// distance factor is the percent-distance from the player, compared to the max follow distance.
				var distFactor:Number = d2 / follow._maxDistanceSqr;
				
				if ( distFactor > 1 ) {
					
					follow.clearTarget();
					node.entity.remove( MonsterFollow );
					node.monster.action = LandMonster.NONE;
					node.motionControl.maxVelocityX = 400;
					continue;
					
				} else if ( d2 < follow._arriveDistanceSqr ) {
					
					node.motionControl.maxVelocityX = 200;
					
					follow._distCheckTime = 1;
					
				} else {
					
					if ( distFactor < 0.6 ) {
						// don't let velocity drop below a certain threshold. very fudgy.
						distFactor = 0.6;
					}
					
					node.motionControl.maxVelocityX = 400*distFactor;
					
					follow._distCheckTime = 1;
					
					
				} //
				
				/**
				 * check time to re-compute target.
				 */
				follow._destCheckTime -= time;
				if ( follow._destCheckTime <= 0 && Math.abs(dx) > 100 ) {
					
					if ( destPoint.x > node.spatial.x ) {
						this.tileHits.directionSearch( node.entity, node.spatial, 1, 3 );
					} else {
						this.tileHits.directionSearch( node.entity, node.spatial, -1, 3 );
					} //
					
					follow._destCheckTime = 0.2;
					
					
				} //
				
			} // end for-loop.
			
		} //
		
		private function targetEntity( follow:MonsterFollow ):Point {
			
			var tSpatial:Spatial = follow._targetSpatial;
			if ( tSpatial == null ) {
				tSpatial = follow._target.get( Spatial );
			}
			return new Point( tSpatial.x, tSpatial.y );
			
		} //
		
		private function targetTile( follow:MonsterFollow ):Point {
			
			return this.tileHits.getTilePoint( follow._tileTarget.tile );
			
		} //
		
		/**
		 * TODO: hacky.
		 * goes through the list of monsters and finds any monsters that are currently
		 * following the player. these are marked as "multiScene" and put to sleep
		 * until the next scene loads.
		 */
		public function markFollowerMonsters( maxFollowers:int=2 ):void {
			
			var player:Entity = ( this.group as LandGroup ).getPlayer();
			var follow:MonsterFollow;
			var dx:Number;
			var dy:Number;

			var curFollows:int = 0;

			for( var node:MonsterFollowNode = this.monsterList.head; node; node = node.next ) {

				this.landData.sceneMustSave = true;
				
				if ( node.monster.mood < 40 ) {
					// only nice monsters will follow every scene.
					//node.monster.multiScene = false;
					continue;
				}
				
				// Monster is currently following the player. if the monster is very close,
				// it will change scenes with the player.
				follow = node.targetInfo;
				if ( follow.target == player ) {
					
					dx = node.spatial.x - follow._targetSpatial.x;
					dy = node.spatial.y - follow._targetSpatial.y;
					
					if ( dx*dx + dy*dy <= 200*200 ) {
						
						follow.player_dx = dx;
						follow.player_dy = dy;
						node.monster.multiScene = true;
						node.entity.sleeping = true;

						if ( curFollows++ > maxFollowers ) {
							return;
						}

						continue;
						
					} //
					
				} // end follow-check.
				
			} // end for-loop.
			
		} //
		
		/**
		 * when a scene changes, the followers that are following the player need to be placed by the player again.
		 */
		public function placeFollowersInScene():void {
			
			var follow:MonsterFollow;
			for( var node:MonsterFollowNode = this.monsterList.head; node; node = node.next ) {
				
				if ( !node.monster.multiScene ) {
					continue;
				}
				
				follow = node.targetInfo;
				
				node.entity.sleeping = false;
				node.spatial.x = follow._targetSpatial.x + follow.player_dx;
				node.spatial.y = follow._targetSpatial.y + follow.player_dy;
				
				// the monster has been placed in a new scene and is no longer a 'multiscene' monster until it follows the player
				// into the next scene.
				node.monster.multiScene = false;
				this.landData.sceneMustSave = true;
				
			} //
			
		} //
		
		/*private function inRange( sp1:Spatial, sp2:Spatial, maxDistSquared:Number ):Boolean {
		
		var dx:Number = sp1.x - sp2.x;
		var dy:Number = sp1.y - sp2.y;
		
		if ( dx*dx + dy*dy <= maxDistSquared ) {
		return true;
		} else {
		return false;
		}
		
		} //*/
		
		/**
		 * get the new tile map after the biome changes.
		 */
		/*public function biomeChanged():void {
		
		//this.tileMap = this.landData.tileMaps["terrain"];
		
		} //*/
		
		private function onFollowAdded( node:MonsterFollowNode ):void {
			
			var follow:MonsterFollow = node.targetInfo;
			
			follow._distCheckTime = 1;
			follow._destCheckTime = 0.2;
			
			if ( follow._target ) {
				follow._targetSpatial = follow._target.get( Spatial );
			}
			
		} //
		
		private function onFollowRemoved( node:MonsterFollowNode ):void {
			node.motionControl.maxVelocityX = 400;
		}
		
		override public function addToEngine(systemManager:Engine):void {
			
			this.monsterList = systemManager.getNodeList( MonsterFollowNode );
			this.monsterList.nodeAdded.add( this.onFollowAdded );
			this.monsterList.nodeRemoved.add( this.onFollowRemoved );
			
		} //
		
		override public function removeFromEngine(systemManager:Engine):void {
			
			this.monsterList.nodeAdded.remove( this.onFollowAdded );
			this.monsterList.nodeRemoved.remove( this.onFollowRemoved );
			this.monsterList = null;
			
		} //
		
	} // class
	
} // package