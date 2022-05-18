package game.scenes.lands.shared.monsters.systems {
	
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.components.SpawnerComponent;
	import game.scenes.lands.shared.monsters.PixieSpawner;
	import game.scenes.lands.shared.monsters.SpawnerBase;
	import game.scenes.lands.shared.monsters.SpiderSpawner;
	import game.scenes.lands.shared.monsters.components.Wildlife;
	import game.scenes.lands.shared.monsters.nodes.MonsterSpawnNode;
	import game.scenes.lands.shared.monsters.nodes.WildlifeNode;
	
	public class MonsterSpawnSystem extends System {
		
		/**
		 * size of the rect tested for creature spawning each iteration.
		 */
		private const TEST_SIZE:int = 512;
		
		private var spawnerList:NodeList;
		
		private var landGroup:LandGroup;
		private var gameData:LandGameData;
		
		private var masterNode:MonsterSpawnNode;
		
		/**
		 * these this in order to only spawn things off-camera.
		 */
		private var viewport:Rectangle;
		private var sceneRect:Rectangle;
		
		private var spawners:Vector.<SpawnerBase>;
		
		private var wildlife:NodeList;
		
		public function MonsterSpawnSystem( landGroup:LandGroup, viewRect:Rectangle ) {
			
			super();
			
			this.landGroup = landGroup;
			
			landGroup.onLeaveScene.add( this.destroyMonsters );
			
			this.gameData = this.landGroup.gameData;
			this.sceneRect = this.landGroup.sceneBounds;
			
			this.viewport = viewRect;
			
			// might want to move this list into the SpawnerComponent
			this.spawners = new Vector.<SpawnerBase>( 2, true );
			this.spawners[0] = new SpiderSpawner( this.gameData );
			this.spawners[1] = new PixieSpawner( this.gameData );
			
		} //
		
		/*private function mouseDownMonster( e:MouseEvent ):void {
		} //
		
		private function mouseUpMonster( e:MouseEvent ):void {
		} //*/
		
		override public function update( time:Number ):void {
			
			if ( this.masterNode == null || this.masterNode.entity.sleeping ) {
				return;
			}
			
			var spawner:SpawnerComponent = this.masterNode.spawner;
			
			if ( (spawner.waitTime-- > 0) || (spawner.monsterCount >= spawner.maxMonsters) ) {
				return;
			} //
			spawner.waitTime = spawner.spawnTestRate;			// reset the wait timer.
			
			// range of spawn test.
			var x0:int, y0:int, x1:int, y1:int;
			
			if ( this.viewport.right <= this.sceneRect.width/2 ) {
				
				x0 = this.viewport.right + Math.random()*( (this.sceneRect.right - TEST_SIZE) - this.viewport.right );
				
			} else {
				
				x0 = Math.random()*( this.viewport.left - this.TEST_SIZE );
				if ( x0 < 0 ) {
					x0 = 0;
				}
				
			} //
			x1 = x0 + this.TEST_SIZE;

			y0 = Math.random()*( this.sceneRect.bottom - TEST_SIZE );
			y1 = y0 + this.TEST_SIZE;

			var numSpawners:int = this.spawners.length-1;

			// conversion from coordinates to tiles.
			for( var i:int = numSpawners; i >= 0; i-- ) {

				if ( !this.spawners[i].isActive( this.gameData ) ) {
					continue;
				}

				for( var y:Number = y0; y0 <= y1; y0 += 32 ) {
					
					for( var x:int = x0; x <= x1; x += 32 ) {
						
						if ( this.spawners[i].canSpawn( x, y, this.gameData ) ) {
							
							this.spawners[i].spawn( this.landGroup, new Spatial( x, y ) ).add( new Wildlife(), Wildlife );
							//this.wildlifeList.push( this.spawners[i].spawn( this.landGroup, new Spatial( x, y ) ) );
							spawner.monsterCount++;
							
							return;			// only spawn one monster every frame. no reason for more.
							
						} //
						
					} // end for-loop.
					
				} // for-loop.
				
			} // for-loop.
			
		} // update()
		
		private function onWildlifeRemoved( node:WildlifeNode ):void {

			if ( this.masterNode ) {
				this.masterNode.spawner.monsterCount--;
			}
			
		} //
		
		private function onNodeAdded( node:MonsterSpawnNode ):void {
			
			this.setSpawnerNode( this.spawnerList.head );
			
		} //
		
		private function onNodeRemoved( node:MonsterSpawnNode ):void {
			
			if ( node == this.masterNode ) {
				
				this.setSpawnerNode( this.spawnerList.head );
				
			} //
			
		} //
		
		public function destroyMonsters():void {

			var node:WildlifeNode = this.wildlife.head;
			while ( node ) {

				var e:Entity = node.entity;
				node = node.next;

				group.removeEntity( e );

			} //

			// can't use a for-loop because the node->next will go to null after remove entity.
			/*for( var node:WildlifeNode = this.wildlife.head; node; node = node.next ) {
				group.removeEntity( node.entity );
			} //*/
	
		} //
		
		/*private function onMonsterAdded( node:MonsterNode ):void {
		if ( this.masterNode ) {
		this.masterNode.spawner.monsterCount++;
		}
		} //
		
		private function onMonsterRemoved( node:MonsterNode ):void {
		if ( this.masterNode ) {
		this.masterNode.spawner.monsterCount--;
		}
		} //*/
		
		private function setSpawnerNode( node:MonsterSpawnNode ):void {
			
			this.masterNode = node;
			if ( node != null ) {
				node.spawner.waitTime = node.spawner.spawnTestRate;
			}
			
		} //
		
		override public function addToEngine( systemManager:Engine ):void {
			
			this.spawnerList = systemManager.getNodeList( MonsterSpawnNode );
			this.spawnerList.nodeAdded.add( this.onNodeAdded );
			this.spawnerList.nodeRemoved.add( this.onNodeRemoved );
			
			this.setSpawnerNode( this.spawnerList.head );
			
			this.wildlife = systemManager.getNodeList( WildlifeNode );
			this.wildlife.nodeRemoved.add( this.onWildlifeRemoved );
			
			/*this.monsterList = systemManager.getNodeList( MonsterNode );
			this.monsterList.nodeAdded.add( this.onMonsterAdded );
			this.monsterList.nodeRemoved.add( this.onMonsterRemoved );
			for( var node:MonsterNode = this.monsterList.head; node; node = node.next ) {
			this.onMonsterAdded( node );
			} //*/
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.spawnerList.nodeAdded.remove( this.onNodeAdded );
			this.spawnerList.nodeRemoved.remove( this.onNodeRemoved );
			
			systemManager.releaseNodeList( WildlifeNode );
			systemManager.releaseNodeList( MonsterSpawnNode );
			//systemManager.releaseNodeList( MonsterNode );
			
		} //
		
	} // End class
	
} // End package