package game.scenes.virusHunter.hand.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.scenes.virusHunter.hand.components.HandState;
	import game.scenes.virusHunter.hand.nodes.HandStateNode;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.shared.nodes.WhiteBloodCellMotionNode;
	
	import org.osflash.signals.Signal;
	
	public class HandManagerSystem extends System
	{
		public function HandManagerSystem( scene:ShipScene, creator:EnemyCreator )
		{
			_scene = scene;
			_creator = creator;
			_removeSplinter = new Signal();
			_loseWeapon = new Signal( String );
			_lostWeapons = new Signal();
			_startingDamage = DamageTarget( _scene.shellApi.player.get( DamageTarget )).damage;
		}
		
		override public function update(time:Number):void
		{	
			var handStateNode:HandStateNode = _handStateNodes.head as HandStateNode;
			var whiteBloodCellNode:WhiteBloodCellMotionNode;
			
			if( handStateNode )
			{
				player = _scene.shellApi.player;
				damageTarget = player.get( DamageTarget );
				
				
				var handState:HandState = handStateNode.handState;
				var target:Entity;
				var player:Entity
				var entitySpawn:Entity;
				var killCountNode:KillCountNode;
				var damageTarget:DamageTarget;
				var sleep:Sleep;
				var spawn:EnemySpawn;
				var hazard:Hazard;
								
				switch( handState.state )
				{
					case handState.BATTLE:
						killCountNode = _killCountNodes.head;
						if( killCountNode.killCount.count[ EnemyType.BACTERIA ] > handState.TOTAL_BACTERIA )
						{
							entitySpawn = _scene.getEntityById( EnemyType.BACTERIA );
							spawn = entitySpawn.get( EnemySpawn );
							spawn.max = 0;
							
							_removeSplinter.dispatch();
							handState.state = handState.TARGET_PLAYER;
						}
						break;
					
					case handState.TARGET_PLAYER:
						if( damageTarget.damage > _startingDamage )
						{
							if( damageTarget.damage >= ( damageTarget.maxDamage / 2 ) - 1 )
							{
								for( whiteBloodCellNode = _whiteBloodCellNodes.head; whiteBloodCellNode; whiteBloodCellNode = whiteBloodCellNode.next )
								{
									hazard = whiteBloodCellNode.entity.get( Hazard );
									hazard.damage = 0.01;
								}
								handState.state = handState.STEAL_SHIELD;
							}
						}
						break;
				
					case handState.STEAL_SHIELD:
						stealWeapon( WeaponType.SHIELD, handState );
						break;
					
					case handState.STEAL_SHOCK:
						stealWeapon( WeaponType.SHOCK, handState );
						break;
					
					case handState.STEAL_SCALPEL:
						stealWeapon( WeaponType.SCALPEL, handState );
						break;
					
					case handState.STEAL_GOO:
						stealWeapon( WeaponType.GOO, handState );
						break;
					
					case handState.STEAL_ANTIGRAV:
						stealWeapon( WeaponType.ANTIGRAV, handState );
						break;
					
					case handState.ROBBED:
						for( whiteBloodCellNode = _whiteBloodCellNodes.head; whiteBloodCellNode; whiteBloodCellNode = whiteBloodCellNode.next )
						{
							sleep = whiteBloodCellNode.sleep;
							if( whiteBloodCellNode.spatial.x < 2000 )
							{
								sleep.sleeping = true;
								_lostWeapons.dispatch();
							}
						}
						break;
					
					case handState.ESCAPE:		
						for( whiteBloodCellNode = _whiteBloodCellNodes.head; whiteBloodCellNode; whiteBloodCellNode = whiteBloodCellNode.next )
						{
							whiteBloodCellNode.whiteBloodCell.state = whiteBloodCellNode.whiteBloodCell.AQUIRE;
							
							target = _scene.getEntityById( "wBCTarget" );
							whiteBloodCellNode.target.target = target.get( Spatial );
						} 
						handState.state = handState.ROBBED;
						break;
				}
				
				if( damageTarget.damage >= damageTarget.maxDamage - .4 )
				{
					damageTarget.damage -= .4;
				}
			}
		}
		
		private function stealWeapon( weaponType:String, handState:HandState ):void
		{
			var whiteBloodCellNode:WhiteBloodCellMotionNode;
			var target:Entity;
			
			for( whiteBloodCellNode = _whiteBloodCellNodes.head; whiteBloodCellNode; whiteBloodCellNode = whiteBloodCellNode.next )
			{
				if( !whiteBloodCellNode.whiteBloodCell.stealingWeapon )
				{
					whiteBloodCellNode.whiteBloodCell.state = whiteBloodCellNode.whiteBloodCell.AQUIRE;
					
					target = _scene.getEntityById( "wBCTarget" );
					whiteBloodCellNode.target.target = target.get( Spatial );
					
					whiteBloodCellNode.whiteBloodCell.stealingWeapon = true;
					handState.state = handState.IDLE;
			
					handState.spatial = whiteBloodCellNode.spatial;
					handState.motion = whiteBloodCellNode.motion;
					
					_loseWeapon.dispatch( weaponType );
					break;
				}
			}	
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_handStateNodes = systemManager.getNodeList( HandStateNode );
			_killCountNodes = systemManager.getNodeList( KillCountNode );
			_whiteBloodCellNodes = systemManager.getNodeList( WhiteBloodCellMotionNode );
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine( systemManager:Engine ) : void
		{
			systemManager.releaseNodeList( HandStateNode );
			systemManager.releaseNodeList( WhiteBloodCellMotionNode );
			super.removeFromEngine( systemManager );
		}
		
		public var _removeSplinter:Signal;
		public var _loseWeapon:Signal;
		public var _lostWeapons:Signal;
		
		private var _startingDamage:Number;
		private var _creator:EnemyCreator;
		private var _handStateNodes:NodeList;
		private var _killCountNodes:NodeList;
		private var _whiteBloodCellNodes:NodeList;
		
		private var _scene:ShipScene;
	}
}

