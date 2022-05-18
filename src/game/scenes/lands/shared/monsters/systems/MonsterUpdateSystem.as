package game.scenes.lands.shared.monsters.systems {
	
	/**
	 * 
	 * Extremely messy monster update system that was pushed through.
	 * Currently don't have any real monster AI - so this performs really random distance tests
	 * and picks something to attack/run towards.
	 * 
	 */

	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.monsters.MonsterFollow;
	import game.scenes.lands.shared.monsters.MonsterWander;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.monsters.nodes.MonsterNode;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	public class MonsterUpdateSystem extends System {
		
		/**
		 * squared distance at which mean monster will attack
		 */
		private const ATTACK_RANGE:int = 300*300;
		/**
		 * squared distance at which nice monster will follow.
		 */
		private const FOLLOW_RANGE:int = 200*200;
		
		/**
		 * squared distance at which an attacking or following monster gives up.
		 * Also note that nice monsters have a small random chance to lose interest and stop
		 * following. The random check is pretty messy at the moment.
		 */
		private const MAX_SIGHT_RANGE:int = 600*600;
		
		private var monsterList:NodeList;
		private var landData:LandGameData;

		/**
		 * in the future, monsters should check all entities of a certain type - though this might require
		 * some sort of space partition.
		 */
		private var player:Entity;
		
		/**
		 * eventually need a way to combine the tile strike and monster strike systems.
		 * this is a quick fix since jordan wants hitting monsters enabled.
		 */
		private var curStrikeTarget:Entity;
		private var curStrikeTime:Number;

		private var hungerTimer:Number;

		public function MonsterUpdateSystem( landGroup:LandGroup ) {
			
			super();
			
			landGroup.onLeaveScene.add( this.destroyMonsters );
			
			this.landData = landGroup.gameData;
			this.player = landGroup.curScene.player;

			this.hungerTimer = 0;

		} //
		
		/*private function mouseDownMonster( evt:MouseEvent, e:Entity ):void {
		} //
		
		private function mouseUpMonster( evt:MouseEvent, e:Entity ):void {
		} //*/
		
		override public function update( time:Number ):void {
			
			var mood:int;

			hungerTimer += time;
			if ( hungerTimer >= 1.0 ) {
				hungerTimer = 0;
			}

			for( var node:MonsterNode = this.monsterList.head; node; node = node.next ) {
				
				if ( node.entity.sleeping ) {
					continue;
				}

				if ( hungerTimer == 0 ) {
					node.monster.hunger++;
					if ( node.monster.hunger > 1000 ) {
						// after over ten minutes of no food, monsters start getting mad.
						if ( Math.random() < 0.1 ) {
							node.monster.mood--;
						}
					}
				}

				if ( node.monster.action == LandMonster.EAT ) {
					node.monster.actionTime += time;
					if ( node.monster.actionTime > 5 ) {
						this.resetState( node );
					}
					continue;
				}

				switch( node.monster.hostility ) {
					
					case LandMonster.NEUTRAL:
						this.doMonsterNeutral( node );
						break;
					
					case LandMonster.MEAN:
						this.doMonsterMean( node );
						break;
					
					case LandMonster.NICE:
						this.doMonsterNice( node );
						break;
					
					default:
						this.resetState( node );
						
				} //

			} // end for-loop.
			
		} //

		/*private function doMonsterWander():void {
		} //

		private function doMonsterAttack():void {
		} //

		private function doMonsterFollow():void {
		} //*/

		private function doMonsterMean( node:MonsterNode ):void {
			
			var monster:LandMonster = node.monster;
			
			if ( monster.mood > 25 ) {
				this.resetState( node );
			}

			switch ( monster.action ) {
				
				case LandMonster.WANDER:
					
					var pSpatial:Spatial = this.player.get( Spatial );
					var dx:Number = pSpatial.x - node.spatial.x;
					var dy:Number = pSpatial.y - node.spatial.y;
					
					if ( dx*dx + dy*dy < this.ATTACK_RANGE ) {
						
						// player too close. attack.
						node.entity.remove( MonsterWander );
						monster.action = LandMonster.ATTACK;
						
						var follow:MonsterFollow = node.entity.get( MonsterFollow ) as MonsterFollow;
						if ( follow ) {
							follow.target = this.player;
						} else {
							node.entity.add( new MonsterFollow( this.player ), MonsterFollow );
						}
						
						SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "hyde" );
						
					} //
					
					break;
				
				case LandMonster.ATTACK:
					
					break;
				
				default:
					monster.action = LandMonster.WANDER;
					node.entity.add( new MonsterWander(), MonsterWander );
					
			} //
			
		} //
		
		private function doMonsterNeutral( node:MonsterNode ):void {
			
			var monster:LandMonster = node.monster;
			
			if ( monster.mood < 25 ) {
				monster.hostility = LandMonster.MEAN;
				return;
			} else if ( monster.mood > 40 ) {
				monster.hostility = LandMonster.NICE;
				return;
			} //
			
			switch ( monster.action ) {
				
				case LandMonster.WANDER:
					
					break;
				
				default:
					monster.action = LandMonster.WANDER;
					node.entity.add( new MonsterWander(), MonsterWander );
					
			} //
			
		} //
		
		private function doMonsterNice( node:MonsterNode ):void {
			
			var monster:LandMonster = node.monster;
			
			switch ( monster.action ) {
				
				case LandMonster.WANDER:
					
					var pSpatial:Spatial = player.get( Spatial );
					
					var dx:Number = pSpatial.x - node.spatial.x;
					var dy:Number = pSpatial.y - node.spatial.y;
					
					if ( dx*dx + dy*dy < this.FOLLOW_RANGE && 54*Math.random() < monster.mood ) {
						
						node.entity.remove( MonsterWander );
						
						var follow:MonsterFollow = node.entity.get( MonsterFollow ) as MonsterFollow;
						if ( follow ) {
							follow.target = this.player;
						} else {
							node.entity.add( new MonsterFollow( this.player ), MonsterFollow );
						}
						monster.action = LandMonster.FOLLOW;
						
					} //
					
					break;
				
				case LandMonster.FOLLOW:
					
					if ( 42*Math.random() > monster.mood ) {
						
						// stop follow.
						follow = node.entity.get( MonsterFollow );
						if ( follow ) {
							follow._target = null;
						}
						monster.action = LandMonster.WANDER;
						node.entity.add( new MonsterWander(), MonsterWander );
						
					} //
					
					break;
				
				default:
					monster.action = LandMonster.WANDER;
					node.entity.add( new MonsterWander(), MonsterWander );
					
			} //
			
		} //
		
		/**
		 * monster was hit by player lightning.
		 */
		private function doStrikeMonster( monster:Entity, strike:LightningStrike ):void {
			
			var life:Life = monster.get( Life );
			if ( life == null ) {
				// this happens when the creature is already dead but the strike still occurs.
				// should not actually happen any more.
				return;
			}

			CharUtils.setState( monster, CharacterState.HURT );

			var monsterData:LandMonster = monster.get( LandMonster ) as LandMonster;
			if ( monsterData != null ) {
				monsterData.mood -= 10;
				if ( monsterData.mood < 0 ) {
					monsterData.mood = 0;
				}

			} //

			if ( life.hittable ) {
				life.hit( 10 );
				AudioUtils.play( this.group, SoundManager.EFFECTS_PATH + "electric_zap_03.mp3", 1, false, SoundModifier.EFFECTS );
			}

			var blink:ColorBlink = monster.get( ColorBlink );
			if ( blink ) {
				blink.start();
				blink.repeat = false;
			}
			// currently no generic way to hit a player/monster?

			var motion:Motion = monster.get( Motion );
			
			motion.velocity.x = strike.strike_dx * 800;
			motion.velocity.y = strike.strike_dy * 800;
			
			motion.acceleration.x = 0;
			motion.acceleration.y = 0;
			
		} //
		
		private function startMean( entity:Entity ):void {
			
			var hitCreator:HitCreator = new HitCreator();
			var hitData:HazardHitData = new HazardHitData();
			hitData.type = "guardHit";
			hitData.knockBackCoolDown = .75;
			hitData.knockBackVelocity = new Point( 1800, 500 );
			hitData.velocityByHitAngle = false;
			entity = hitCreator.makeHit( entity, HitType.HAZARD, hitData, this.group );
			
			SkinUtils.setSkinPart( entity, SkinUtils.EYES, "monster" );
			
		} //
		
		private function resetState( node:MonsterNode ):void {
			
			var mood:int = node.monster.mood;
			
			if ( mood < 25 ) {
				
				if ( node.monster.hostility != LandMonster.MEAN ) {
					node.monster.hostility = LandMonster.MEAN;
					this.startMean( node.entity );
				}
				
			} else if ( mood < 40 ) {
				
				if ( node.monster.hostility != LandMonster.NEUTRAL ) {
					node.monster.hostility = LandMonster.NEUTRAL;
				}
				
			} else {
				
				if ( node.monster.hostility != LandMonster.NICE ) {
					node.monster.hostility = LandMonster.NICE;
				}
				
			} //
			
			node.monster.action = LandMonster.NONE;
			
		} //
		
		public function destroyMonsters():void {
			
			for( var node:MonsterNode = this.monsterList.head; node; node = node.next ) {
				
				node.entity.sleeping = true;
				
				if ( !node.monster.multiScene ) {
					
					// set entity to sleeping so it doesn't do anything in the current frame before it gets destroyed.
					//node.entity.sleeping = true;
					this.group.removeEntity( node.entity, true );
				}
				
			} //
			
		} //
		
		private function monsterAdded( node:MonsterNode ):void {
			
			var display:DisplayObjectContainer = ( node.entity.get( Display ) as Display ).displayObject as DisplayObjectContainer;
			var target:LightningTarget = new LightningTarget( display, 0.05 );
			target.strikeFunc = this.doStrikeMonster;
			
			node.entity.add( target, LightningTarget );
			
		} //
		
		private function monsterRemoved( node:MonsterNode ):void {
			
			var target:LightningTarget = ( node.entity.get( LightningTarget ) as LightningTarget );
			target.enabled = false;
			target.strikeFunc = null;
			
			node.entity.remove( LightningTarget );
			
		} //
		
		override public function addToEngine(systemManager:Engine):void {
			
			this.monsterList = systemManager.getNodeList( MonsterNode );
			
			for( var node:MonsterNode = this.monsterList.head; node; node = node.next ) {
				this.monsterAdded( node );
			} //
			
			this.monsterList.nodeAdded.add( this.monsterAdded );
			this.monsterList.nodeRemoved.add( this.monsterRemoved );
			
		} //
		
		override public function removeFromEngine(systemManager:Engine):void {
			
			this.monsterList.nodeAdded.remove( this.monsterAdded );
			this.monsterList.nodeRemoved.remove( this.monsterRemoved );
			
		} //
		
	} // class
	
} // package