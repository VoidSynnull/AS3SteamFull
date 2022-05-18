package game.scenes.lands.shared.systems {

	/**
	 * This class handles both tile blasting - destruction of regular tiles,
	 * and tile explosions. there isn't a real reason to separate the two functions now,
	 * though it's not strictly right.
	 * 
	 * this class is a hold-over from a very early version of land and should be cleaned up.
	 */

	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.components.TileBlaster;
	import game.scenes.lands.shared.nodes.LandEditNode;
	import game.scenes.lands.shared.nodes.LandGameNode;
	import game.scenes.lands.shared.nodes.LandHazardNode;
	import game.scenes.lands.shared.particles.TileBlastEffect;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	
	import org.flintparticles.twoD.renderers.DisplayObjectRenderer;

	public class BlastTileSystem extends System {

		private var blastEffect:TileBlastEffect;
		private var blastList:Vector.<TileSelector>;

		/**
		 * node list of edit nodes - which should only ever be the masterEditNode.
		 */
		private var editNodeList:NodeList;
		private var masterEditNode:LandEditNode;

		/**
		 * special tile information from the landGameData object of the gameNode.
		 */
		private var specialTiles:Dictionary;
		private var gameNodeList:NodeList;

		/**
		 * things that can get hit by explosions.
		 */
		private var hazardNodes:NodeList;

		public function BlastTileSystem( blastContainer:DisplayObjectContainer ) {

			super();

			this.createBlastEffect( blastContainer );

		} //

		override public function update( time:Number ):void {

			if ( this.masterEditNode == null || this.masterEditNode.entity.sleeping ) {
				return;
			}

			this.blastEffect.update( time );
			if ( this.blastList.length <= 0 ) {
				return;
			}

			var count:int = Math.min( 4, this.blastList.length );

			this.blastEffect.setParticleScale( 0.5, 2 );
			this.blastEffect.setCount( 5 );

			var updateRect:Rectangle = new Rectangle();
			var size:int;

			for( var i:int = count-1; i >= 0; i-- ) {

				var select:TileSelector = this.blastList[i];
				var tile:LandTile = select.tile;

				size = select.tileMap.tileSize;

				if ( (tile.type & select.tileType.type) == 0 ) {

					// type no longer exists at this tile. maybe it got blasted already.
					this.blastList[i] = null;
					continue;

				} //

				tile.type &= ~select.tileType.type;		// an XOR here is dangerous because multi-explosions regenerate land

				// here could actually combine update rects if they overlap.
				updateRect.setTo( tile.col*size, tile.row*size, size, size );
				select.tileMap.layer.renderArea( updateRect );

				this.blastEffect.bitmap = select.tileType.colorBitmap;

				this.blastEffect.setBlastCenter( (tile.col+0.5)*size, (tile.row+0.5)*size );
				this.blastEffect.start();

			} //

			/*if ( count <= 0 ) {
				return;
			}*/

			this.masterEditNode.audio.playCurrentAction( "destroy" );

			var special:TileTypeSpecial;
			// the signals happen after the explosions to avoid explosion doubling.
			// also might just use one signal that fires for everything destroyed.
			for( i = count-1; i >= 0; i-- ) {
				
				select = this.blastList[i];

				if ( select == null ) {		// got marked off because the select was empty by the time it was exploded.
					continue;
				}

				special = this.specialTiles[ select.tileType ];
				if ( special ) {
					if ( special.specialType == "explode" ) {
						this.doTileExplosion( select.tile, select.tileMap, 160 );
					} else if ( special.specialType == "explode_trap" ) {
						this.doTileExplosion( select.tile, select.tileMap, 160 );
					}
				}

				this.masterEditNode.blaster.onTileBlasted.dispatch( select.tile, select.tileType, select.tileMap );

			} //
			
			this.blastList.splice( 0, count );

		} //

		/**
		 * explodes a radius and damages nearby entities.
		 */
		public function doTileExplosion( tile:LandTile, tileMap:TileMap, radius:Number ):void {

			var tx:Number = this.masterEditNode.game.gameData.mapOffsetX + tile.col*tileMap.tileSize;
			var ty:Number = tile.row*tileMap.tileSize;

			var dx:Number;
			var dy:Number;
			var d:Number;

			// check hit nodes. maybe there's a way to get this into the hazard system?
			for( var node:LandHazardNode = this.hazardNodes.head; node; node = node.next ) {

				dx = node.spatial.x - tx;
				dy = node.spatial.y - ty;

				d = dx*dx + dy*dy;

				if ( d < radius*radius ) {

					if ( d < 1 ) {
						d = 1;
						dx = 1;
					}
					d = Math.sqrt( d );
					dx /= d;
					dy /= d;

					node.life.forceHit( 4000/(d+10) );

					node.motion.velocity.x += 40000*dx/d;
					node.motion.velocity.y += 40000*dy/d;

				} //

			} // for-loop.
			
			this.blastRadius( tileMap.layer, tx, ty, radius );

		} //

		/**
		 * explodes a radius and damages nearby entities.
		 */
		public function doExplosion( x:Number, y:Number, layer:TileLayer, radius:Number ):void {

			var dx:Number;
			var dy:Number;
			var d:Number;
			
			// check hit nodes. maybe there's a way to get this into the hazard system?
			for( var node:LandHazardNode = this.hazardNodes.head; node; node = node.next ) {
				
				dx = node.spatial.x - x;
				dy = node.spatial.y - y;
				
				d = dx*dx + dy*dy;
				
				if ( d < radius*radius ) {
					
					if ( d < 1 ) {
						d = 1;
						dx = 1;
					}
					d = Math.sqrt( d );
					dx /= d;
					dy /= d;
					
					node.life.forceHit( 4000/(d+10) );
					
					node.motion.velocity.x += 40000*dx/d;
					node.motion.velocity.y += 40000*dy/d;
					
				} //
				
			} // for-loop.
			
			this.blastRadius( layer, x, y, radius );

		} //

		public function blastRadius( layer:TileLayer, x:Number, y:Number, radius:Number ):void {

			var maps:Vector.<TileMap> = layer.getMaps();
			var tmap:TileMap;
			
			var deltaXMax:Number;
			
			var row:int;
			var maxRow:int;
			var col:int;
			var maxCol:int;
			
			var tile:LandTile;

			x -= this.masterEditNode.game.gameData.mapOffsetX;

			var blaster:TileBlaster = this.masterEditNode.blaster;
			var deltaY:Number;

			for( var i:int = maps.length-1; i >= 0; i-- ) {

				tmap = maps[i];

				deltaY = -radius;
				row = ( y + deltaY ) / tmap.tileSize;
				if ( row < 0 ) {
					row = 0;
				}

				maxRow = ( y + radius ) / tmap.tileSize;
				if ( maxRow >= tmap.rows ) {
					maxRow = tmap.rows-1;
				}

				for( ; row <= maxRow; row++ ) {

					deltaXMax = Math.sqrt( radius*radius - deltaY*deltaY );
					deltaY += tmap.tileSize;

					col = ( x - deltaXMax ) / tmap.tileSize;
					if ( col < 0 ) {
						col = 0;
					}
					maxCol = ( x + deltaXMax ) / tmap.tileSize;
					if ( maxCol >= tmap.cols ) {
						maxCol = tmap.cols-1;
					}

					for( ; col <= maxCol; col++ ) {

						tile = tmap.getTile( row, col );
						if ( tile.type == 0 ) {
							continue;
						}

						blaster.addTile( new TileSelector( tile, tmap.getType(tile), tmap ) );

					} // end column-loop.
					
				} // tileMap for-loop.
				
			} // y-offset for-loop.

		} //

		/**
		 * blasts a semi-circle of tiles, directed downwards from the x,y coordinate.
		 * 
		 * same as blastRadius but deltaY starts at 0 instead of -radius.
		 */
		public function blastSemiCircle( layer:TileLayer, x:Number, y:Number, radius:Number ):void {
			
			var maps:Vector.<TileMap> = layer.getMaps();
			var tmap:TileMap;
			
			var deltaXMax:Number;
			
			var row:int;
			var maxRow:int;
			var col:int;
			var maxCol:int;
			
			var tile:LandTile;
			
			x -= this.masterEditNode.game.gameData.mapOffsetX;

			var blaster:TileBlaster = this.masterEditNode.blaster;
			var deltaY:Number;
			
			for( var i:int = maps.length-1; i >= 0; i-- ) {

				tmap = maps[i];
				
				deltaY = 0;
				row = ( y ) / tmap.tileSize;
				if ( row < 0 ) {
					row = 0;
				}

				maxRow = ( y + radius ) / tmap.tileSize;
				if ( maxRow >= tmap.rows ) {
					maxRow = tmap.rows-1;
				}

				/*if ( tmap.tileSize == 64 ) {
					trace( "start row: " + row );
					trace( "max row: " + maxRow );
				}*/

				for( ; row <= maxRow; row++ ) {
					
					deltaXMax = Math.sqrt( radius*radius - deltaY*deltaY );
					deltaY += tmap.tileSize;
					
					col = ( x - deltaXMax ) / tmap.tileSize;
					if ( col < 0 ) {
						col = 0;
					}
					maxCol = ( x + deltaXMax ) / tmap.tileSize;
					if ( maxCol >= tmap.cols ) {
						maxCol = tmap.cols-1;
					}

					/*if ( tmap.tileSize == 64 ) {
						trace( "base x : " + x );
						trace( "min x : " + (x - deltaXMax) );
						trace( "max x: " + ( x + deltaXMax ) );
						trace( "start col: " + col );
						trace( "max col: " + maxCol );
					}*/

					for( ; col <= maxCol; col++ ) {
						
						tile = tmap.getTile( row, col );
						if ( tile.type == 0 ) {
							continue;
						}

						blaster.addTile( new TileSelector( tile, tmap.getType(tile), tmap ) );
						
					} // end column-loop.
					
				} // tileMap for-loop.
				
			} // y-offset for-loop.

		} //

		/**
		 * creates the visual effect for the tile-destroy-blast thingy.
		 */
		private function createBlastEffect( blastParent:DisplayObjectContainer ):void {
			
			this.blastEffect = new TileBlastEffect();
			this.blastEffect.init();
			
			//var e:Entity = EmitterCreator.create( this, this.curScene.hitContainer, this.blaster, 100, 1000, null, "blaster", null, false );
			//this.blaster.useInternalTick = true;

			var blastDisplay:DisplayObjectRenderer = new DisplayObjectRenderer();
			blastDisplay.mouseEnabled = blastDisplay.mouseChildren = false;

			/**
			 * blast display needs to be placed at the origin so when different tiles are blasted,
			 * the effect doesn't move.
			 */
			blastDisplay.x = 0;
			blastDisplay.y = 0;
			blastDisplay.addEmitter( this.blastEffect );

			blastParent.addChild( blastDisplay );

		} //

		private function gameNodeAdded( node:LandGameNode ):void {

			this.specialTiles = node.game.gameData.tileSpecials;

		} //

		/**
		 * There should only ever be ONE node added.
		 */
		private function editNodeAdded( node:LandEditNode ):void {

			if ( this.masterEditNode == null ) {

				this.setMasterEditNode( node );

			}

		} //

		private function editNodeRemoved( node:LandEditNode ):void {

			if ( this.masterEditNode == node ) {

				if ( this.editNodeList.head ) {
					this.setMasterEditNode( this.editNodeList.head );
				} else {
					this.masterEditNode = null;
				}

			} //

		} //

		private function setMasterEditNode( node:LandEditNode ):void {

			this.masterEditNode = node;
			this.blastList = node.blaster.blastTiles;

			node.blaster.blaster = this.blastEffect;
		
		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.hazardNodes = systemManager.getNodeList( LandHazardNode );

			// only use the gameNodeList to get the special tiles to find explosive tiles.
			this.gameNodeList = systemManager.getNodeList( LandGameNode );
			this.gameNodeList.nodeAdded.add( this.gameNodeAdded );
			if ( this.gameNodeList.head ) {
				this.gameNodeAdded( this.gameNodeList.head );
			}

			this.editNodeList = systemManager.getNodeList( LandEditNode );
			this.editNodeList.nodeAdded.add( this.editNodeAdded );
			this.editNodeList.nodeRemoved.add( this.editNodeRemoved );

			if ( this.editNodeList.head ) {
				this.setMasterEditNode( this.editNodeList.head );
			}

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.gameNodeList.nodeAdded.remove( this.gameNodeAdded );
			this.gameNodeList = null;

			this.editNodeList.nodeAdded.remove( this.editNodeAdded );
			this.editNodeList.nodeRemoved.remove( this.editNodeRemoved );

			this.hazardNodes = null;

			this.editNodeList = null;

		} //

	} // class

} // package