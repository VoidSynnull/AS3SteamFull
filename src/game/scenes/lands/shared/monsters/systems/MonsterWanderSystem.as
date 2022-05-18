package game.scenes.lands.shared.monsters.systems {
	
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.components.TileInteractor;
	import game.scenes.lands.shared.monsters.MonsterWander;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.monsters.nodes.MonsterWanderNode;
	import game.scenes.lands.shared.systems.LandInteractionSystem;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	
	public class MonsterWanderSystem extends System {
		
		private var monsterList:NodeList;
		
		/**
		 * tells what spaces are walkable.
		 */
		private var tileHits:TileBitmapHits;
		
		private var propMap:TileMap;
		private var tileSpecials:Dictionary;
		private var gameData:LandGameData;
		
		private var interactions:LandInteractionSystem;
		
		/**
		 * list of tile type ids that can be eaten by a monster.
		 */
		private var foodTypes:Vector.<uint>;
		
		public function MonsterWanderSystem( landGroup:LandGroup ) {
			
			super();
			
			var gameData:LandGameData = landGroup.gameData;
			
			this.tileHits = gameData.tileHits;
			this.tileSpecials = gameData.tileSpecials;
			
			this.gameData = gameData;
			this.propMap = gameData.getDecalMap();
			
			this.interactions = landGroup.getSystem( LandInteractionSystem ) as LandInteractionSystem;
			
			this.initFoodTypes();
			
		} //
		
		// TODO: maybe move this into a master class that tracks all the different KINDS of specials.
		// all this is very preliminary.
		private function initFoodTypes():void {
			
			this.foodTypes = new Vector.<uint>();
			
			var special:TileTypeSpecial;
			var specials:Dictionary = this.tileSpecials;
			for ( var type:TileType in specials ) {
				
				special = specials[type];
				if ( special.specialType == "food" ) {
					this.foodTypes.push( type.type );
				} //
				
			} //
			
		} //
		
		override public function update( time:Number ):void {
			
			var wander:MonsterWander;
			
			for( var node:MonsterWanderNode = this.monsterList.head; node; node = node.next ) {
				
				if ( node.entity.sleeping ) {
					continue;
				}
				
				wander = node.wander;
				wander.waitTimer -= time;
				if ( wander.waitTimer > 0 ) {
					continue;
				}
				
				if ( node.monster.hunger > 10 || node.life.curLife < 10 ) {
					
					if ( this.searchFood( node ) ) {
						node.monster.action = LandMonster.EAT;
						node.entity.remove(MonsterWander);
						continue;
					}
					
				} //
				
				wander.waitTimer = wander.maxWaitTime*Math.random();
				
				if ( Math.random() < 0.5 ) {
					this.tileHits.directionSearch( node.entity, node.spatial, -1 );
				} else {
					this.tileHits.directionSearch( node.entity, node.spatial, 1 );
				} //
				
			} // end for-loop.
			
		} // update()
		
		// this doesnt belong here. this is just ... for now.
		private function searchFood( node:MonsterWanderNode ):Boolean {
			
			var spatial:Spatial = node.spatial;
			
			if(!this.propMap) return false;
			if(!gameData) return false;
			
			var tile:LandTile = this.propMap.getTileAt( -gameData.mapOffsetX + spatial.x, spatial.y );
			
			if(!tile)return false;
			
			// TODO. MIGHT add checks here to make sure the monster doesn't try to tunnel?
			tile = this.findTileOfType( tile.row-3, tile.row+3,
				tile.col-3, tile.col+3, this.propMap, this.foodTypes );
			
			if(!tile) return false;
			
			// now have food to try to eat. this is where things get tricky.
			
			// this is the tile selector used to control the monster's movement. now what?
			var selector:TileSelector = new TileSelector( tile, this.propMap.getType(tile), this.propMap );
			
			var tileInteractor:TileInteractor = this.interactions.interactTile( node.entity, selector );
			if(!tileInteractor) return false;
			tileInteractor.onInteracted.addOnce( this.onEatingDone );
			
			return true;
			
		} //
		
		private function onEatingDone( actor:Entity, special:TileTypeSpecial ):void {
			
			// for now, just go back into 'wander' mode.
			var monster:LandMonster = actor.get( LandMonster ) as LandMonster;
			if ( monster == null ) {
				// that's fecking weird.
				return;
			}
			
			if ( special.specialType == "food" ) {
				
				// in the future, it might be some other kind of interaction.
				
				monster.mood += special.bonus/10;
				if ( monster.mood > 64 ) {
					monster.mood = 64;
				}
				
				// TODO: change hunger amount based on tile being eaten. this is a bit complex however.
				// the tile no longer exists in the target and the Destination comp. doesnt have this information.
				// !! need a new signal from LandInteraction.
				monster.hunger -= special.bonus/5;
				if ( monster.hunger < 0 ) {
					
					var amount:int = special.bonus/5;
					if ( monster.hostility == LandMonster.MEAN) {
						amount *= 0.75;
					} else if ( monster.hostility == LandMonster.NICE ) {
						amount *= 1.5;
					} //
					var sp:Spatial = actor.get( Spatial );
					if ( sp ) {
						( this.group as LandGroup ).spawnPoptanium( sp.x, sp.y, amount );
					}
					monster.hunger = 0;
					
				} //
				
				
				
			} //
			
			monster.action = LandMonster.WANDER;
			if ( actor.get( MonsterWander ) == null ) {
				actor.add( new MonsterWander() );
			}
			
		} //
		
		/**
		 * attempts to find a single tile with one of the listed tile types.
		 * TODO: move this to a TileSearch class. Can be used for MapGenerator.as also.
		 */
		private function findTileOfType( minRow:int, maxRow:int,
										 minCol:int, maxCol:int,
										 tMap:TileMap, types:Vector.<uint> ):LandTile {
			
			if ( minRow < 0 ) {
				minRow = 0;
			}
			if ( maxRow >= tMap.rows ) {
				maxRow = tMap.rows-1;
			}
			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= tMap.cols ) {
				maxCol = tMap.cols-1;
			}
			
			var curType:uint;
			var landTile:LandTile;
			
			// THIS LOOP CAN BE SPED UP BY COPYING THE ROW,COL TILE MATRIX LOCALLY.
			// ONLY ADVANCE THE ROW MATRIX IN THE FIRST LOOP.
			for( var r:int = minRow; r <= maxRow; r++ ) {
				
				for( var c:int = minCol; c <= maxCol; c++ ) {
					
					landTile = tMap.getTile(r,c);
					curType = landTile.type;
					if ( curType == 0 ) {
						continue;
					}
					
					for( var i:int = types.length-1; i >= 0; i-- ) {
						
						if ( curType == types[i] ) {
							return landTile;
						}
						
					} // type-loop.
					
					
				} // for-loop.
				
			} // for-loop.
			
			return null;
			
		} //
		
		override public function addToEngine(systemManager:Engine):void {
			
			this.monsterList = systemManager.getNodeList( MonsterWanderNode );
			
		} //
		
	} // class
	
} // package