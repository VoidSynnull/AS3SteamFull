package game.scenes.lands.shared.systems {
	
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.nodes.LandMeteorNode;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.util.AudioUtils;
	
	
	public class LandMeteorSystem extends System {
		
		private var meteorNodes:NodeList;
		
		private var tileHits:TileBitmapHits;
		
		private var blastSystem:BlastTileSystem;
		
		private var fgLayer:TileLayer;
		
		public function LandMeteorSystem() {
			
			super();
			
		} //
		
		override public function update( time:Number ):void {

			var sp:Spatial;

			for( var node:LandMeteorNode = this.meteorNodes.head; node; node = node.next ) {

				sp = node.spatial;

				if ( sp.x < -40 || sp.x > 3000 || sp.y > 3000 ) {
					node.meteor.onRemoved.dispatch();
					this.group.removeEntity( node.entity, true );
					continue;
				} //

				if ( !this.tileHits.isEmpty( sp.x, sp.y ) ) {

					// HIT. Make an explosion.
					// the whole blast system needs to be re-worked.
					if ( this.blastSystem != null ) {
						this.blastSystem.doExplosion( sp.x, sp.y, this.fgLayer, 180 );
					}

					AudioUtils.play( this.group , SoundManager.EFFECTS_PATH + "explosion_01.mp3", 1, false, SoundModifier.EFFECTS );

					if ( node.meteor.spawnPoptanium ) {
						( this.group as LandGroup ).spawnPoptanium( sp.x, sp.y, 50 );
					}

					// destroy the meteor.
					node.meteor.onRemoved.dispatch();
					this.group.removeEntity( node.entity, true );

				} //

			} // for-loop.

		} // update()
		
		private function nodeRemoved( node:LandMeteorNode ):void {
			
			/*if ( this.meteorNodes.head == null ) {
			
			// no meteors left. might as well remove system.
			this.group.removeSystem( this, true );
			
			}*/
			
		} //
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.meteorNodes = systemManager.getNodeList( LandMeteorNode );
			this.meteorNodes.nodeRemoved.add( this.nodeRemoved );
			
			var gameData:LandGameData = ( this.group as LandGroup ).gameData;
			this.tileHits = gameData.tileHits;
			this.fgLayer = gameData.getFGLayer();
			
			// not a very good way to handle this right now.
			this.blastSystem = group.getSystem( BlastTileSystem ) as BlastTileSystem;
			
		}
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.blastSystem = null;
			this.tileHits = null;
			
			this.meteorNodes.nodeRemoved.remove( this.nodeRemoved );
			this.meteorNodes = null;
			
		} //
		
	} // class
	
} // package