package game.scenes.lands.shared.systems {

	/**
	 * this class handles all the hazards for tile-lands.
	 * Basically anything that hurts the player or npcs.
	 * 
	 * Might make this into a more general LandBitmapHitSystem - so anything
	 * that relies on an entity's current bitmapCollider hit color.
	 */

	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.monsters.MonsterFollow;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.nodes.LandGameNode;
	import game.scenes.lands.shared.nodes.LandHazardNode;

	public class LandHazardSystem extends System {

		/**
		 * hard-coding these until the lava/water hits can be done based on tile hit alone.
		 * the only alternative would be to loop through a list of enitites and check their ids
		 * for lava/water -- every frame.
		 * 
		 * if the collision group had an accessor to the allHitsData could map hit color
		 * to hit type.
		 */
		private const lavaHitColor:int = 0x667000;
		private const waterHitColor:int = 0x0000bb;

		private var colliderNodes:NodeList;

		/**
		 * used for hit sounds. i dunno.
		 */
		private var gameNodes:NodeList;

		private var player:Entity;

		public function LandHazardSystem( group:LandGroup ) {

			super();

			this.player = group.getPlayer();

		} //

		override public function update( time:Number ):void {

			for( var node:LandHazardNode = this.colliderNodes.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				if ( node.hazardCollider.isHit ) {

					if ( node.entity == this.player ) {			// PLAYER WAS HIT

						var monster:LandMonster = node.current.hit.get( LandMonster ) as LandMonster;
						if ( monster ) {

							var follow:MonsterFollow = node.current.hit.get( MonsterFollow ) as MonsterFollow;
							if ( follow ) {
								follow._destCheckTime = 1;	// monster stops chasing for one second.
							}
							node.life.hit( 15*monster.data.scale );
							( this.gameNodes.head as LandGameNode ).audio.playCurrentAction( "monster_attack" );

						} else {
							node.life.hit( 15 );
							( this.gameNodes.head as LandGameNode ).audio.playCurrentAction( "player_hurt" );
						}

					} else {
						// monster hit a hazard.
						node.life.hit( 15 );
					} //

					node.hazardCollider.coolDown = node.life.hitResetTime;
					node.blink.start();

				} else if ( node.waterCollider.isHit ) {

					if ( node.bitmapCollider.centerColor == this.waterHitColor && node.entity == this.player ) {

						// NOTE: currently monsters dont have breath limits in water - they die too easily.
						if ( !node.waterCollider.surface ) {

							node.life.drainHit( 10*time );

						} //

					} else if ( node.bitmapCollider.centerColor == this.lavaHitColor || node.bitmapCollider.color == this.lavaHitColor ) {

						node.life.drainHit( 50*time );

					}

				}
				if ( node.life.draining ) {

					node.blink.continuous();
					node.life.draining = false;
					if ( node.entity == this.player ) {
						( this.gameNodes.head as LandGameNode ).audio.playCurrentAction( "player_hurt" );
					} //

				} else {
					node.blink.repeat = false;
				}

			} // for-loop.

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.colliderNodes = systemManager.getNodeList( LandHazardNode );

			this.gameNodes = systemManager.getNodeList( LandGameNode );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			this.colliderNodes = null;
			this.gameNodes = null;

		} //

	} // End class

} // End package