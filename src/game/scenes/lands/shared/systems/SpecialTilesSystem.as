package game.scenes.lands.shared.systems {
	
	/**
	 *
	 * check hits for special ability type tiles. probably need to move the TNT explosions into this class
	 * as well as anything special that happens ever.
	 *
	 */
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.classes.TimedTile;
	import game.scenes.lands.shared.components.HitTileComponent;
	import game.scenes.lands.shared.nodes.LandColliderNode;
	import game.scenes.lands.shared.nodes.SpecialTilesNode;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.util.AudioUtils;
	
	public class SpecialTilesSystem extends System {
		
		private var colliderNodes:NodeList;
		private var specialNodes:NodeList;
		
		public function SpecialTilesSystem() {
			
			super();
			
		} //
		
		override public function update( time:Number ):void {
			
			var hitTile:HitTileComponent;
			
			// A special node is a game-wide node (only one node per system) that tracks information about special tiles onscreen.
			// currently it only contains timedTiles, but other information like tnt tiles, trap tiles, might be added?
			var specNode:SpecialTilesNode = specialNodes.head;
			if ( specNode == null ) {			// no specials information.
				return;
			}
			
			// every creature, npc, player in lands has a collider node, tracking what tile they're currently standing on.
			for( var node:LandColliderNode = this.colliderNodes.head; node; node = node.next ) {
				
				hitTile = node.hitTile;
				if ( !hitTile.hitChanged ) {
					continue;
				} //
				
				var special:TileTypeSpecial = specNode.gameData.gameData.tileSpecials[ hitTile.tileType ];
				if ( !special ) {
					continue;
				}
				if ( special.specialType == "crumble" ) {
					
					var timer:TimedTile = new TimedTile( new TileSelector( hitTile.tile, hitTile.tileType,hitTile.tileMap ), 0.5 );
					timer.blastOnComplete = true;
					specNode.timers.addTile( timer );
					
				} else if ( special.specialType == "explode_trap" ) {

					var timer2:TimedTile = new TimedTile( new TileSelector( hitTile.tile, hitTile.tileType,hitTile.tileMap ), 0.1 );
					timer2.blastOnComplete = true;
					timer2.crumble = false;
					specNode.timers.addTile( timer2 );

				} else if ( special.specialType == "trap" ) {
					
					var curTile:TileSelector = new TileSelector(hitTile.tile, hitTile.tileType, hitTile.tileMap);
					var landGroup:LandGroup = this.group as LandGroup;
					
					( curTile.tileType as ClipTileType ).swapClipTile( landGroup.gameData.getFGLayer(),
						curTile, special.swapTile, special.offsetX, special.offsetY );

					if(special.sound != ""){
						AudioUtils.play( landGroup, SoundManager.EFFECTS_PATH + special.sound, 1, false, SoundModifier.EFFECTS );
					}
				}

			} // end collider-loop.
			
		} // update()
		
		/*
		private function onNodeAdded( node:ActiveTilesNode ):void {
		} //
		
		private function onNodeRemoved( node:ActiveTilesNode ):void {
		} //*/
		
		override public function addToEngine( systemManager:Engine ):void {
			
			this.colliderNodes = systemManager.getNodeList( LandColliderNode );
			this.specialNodes = systemManager.getNodeList( SpecialTilesNode );
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.colliderNodes = null;
			this.specialNodes = null;
			
		} //
		
	} // End class
	
} // End package