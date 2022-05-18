package game.scenes.cavern1.shared.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.cavern1.shared.components.MagneticData;
	import game.scenes.cavern1.shared.nodes.MagnetNode;
	import game.scenes.cavern1.shared.nodes.MagneticNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.Utils;
	
	public class MagnetSystem extends System
	{
		private var _magnetics:NodeList;
		private var _magnets:NodeList;
		
		public function MagnetSystem()
		{
			super();
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function update(time:Number):void
		{
			for(var magnetNode:MagnetNode = this._magnets.head; magnetNode; magnetNode = magnetNode.next)
			{
				if(EntityUtils.sleeping(magnetNode.entity))
				{
					continue;
				}
				
				var closestDistance:Number = Number.MAX_VALUE;
				var closestNode:MagneticNode = null;
				
				//Compare magnets to magnetics.
				for(var magneticNode:MagneticNode = this._magnetics.head; magneticNode; magneticNode = magneticNode.next)
				{
					//Don't compare a magnet and magnetic if they're the same Entity.
					if(magnetNode.entity == magneticNode.entity)
					{
						continue;
					}
					
					if(EntityUtils.sleeping(magneticNode.entity))
					{
						continue;
					}
					
					if(magnetNode.magneticData.polarity != 0 && magneticNode.magneticData.polarity != 0)
					{
						var distance:Number = Utils.distance(magnetNode.spatial.x, magnetNode.spatial.y, magneticNode.spatial.x, magneticNode.spatial.y);
						var totalRadius:Number = magnetNode.magneticData.radius + magneticNode.magneticData.radius;
						
						if(distance <= totalRadius)
						{
							//Movable
							if(magneticNode.magnetic.isMovable)
							{
								if(distance < 20 && magnetNode.spatial.y < magneticNode.spatial.y)
								{
									if(isAttracted(magnetNode.magneticData.polarity, magneticNode.magneticData.polarity))
									{
										continue;
									}
								}
								var strength:Number;
								
								var distanceX:Number = Math.abs(magnetNode.spatial.x - magneticNode.spatial.x);
								if(distanceX < 20)
								{
									strength = magnetNode.magnet.strength * (distanceX / 20);
								}
								else
								{
									strength = magnetNode.magnet.strength;
								}
								
								if(!isAttracted(magnetNode.magneticData.polarity, magneticNode.magneticData.polarity))
								{
									strength *= -1;
								}
								
								//Move the magnetic towards the magnet.
								if(magnetNode.spatial.x < magneticNode.spatial.x)
								{
									magneticNode.motion.velocity.x = -strength;
								}
								else
								{
									magneticNode.motion.velocity.x = strength;
								}
							}
							//Not movable
							else
							{
								if(distance < closestDistance)
								{
									//If attracted to a magnetic, stop potential spins and set gravity to 0.
									//The magnet will do the work.
									if(isAttracted(magnetNode.magneticData.polarity, magneticNode.magneticData.polarity))
									{
										magnetNode.charMotionControl.spinEnd = true;
										magnetNode.charMotionControl.gravity = 0;
										magnetNode.motionControl.lockInput = true;
									}
									else
									{
										//Don't repel if you're just walking on a platform under a magnetic object. It's annoying.
										if(magnetNode.platformCollider.isHit)
										{
											continue;
										}
										//Gravity is okay if repelling. For now.
										magnetNode.charMotionControl.gravity = MotionUtils.GRAVITY;
									}
									
									closestDistance = distance;
									closestNode = magneticNode;
									
									magnetNode.charMotionControl.allowAutoTarget = false;
								}
							}
							
							/*
							if(magnetNode.spatial.x > magneticNode.spatial.x)
							{
								strength *= -1;
							}
							
							if(magneticNode.magnetic.isMovable)
							{
								magneticNode.motion.velocity.x = strength;
								//magneticNode.motion.velocity.y = Math.sin(radians) * strength;
							}
							else
							{
								magnetNode.motion.velocity.x = strength;
								//magnetNode.motion.velocity.y = Math.sin(radians + Math.PI) * strength;
							}*/
						}
					}
				}
				
				if(closestNode == null)
				{
					magnetNode.charMotionControl.gravity = MotionUtils.GRAVITY;
				}
				else
				{
					this.handleMagnetMovement(magnetNode, closestNode);
				}
			}
		}
		
		private function handleMagnetMovement(magnetNode:MagnetNode, magneticNode:MagneticNode):void
		{
			var distance:Number = Utils.distance(magnetNode.spatial.x, magnetNode.spatial.y, magneticNode.spatial.x, magneticNode.spatial.y);
			var totalRadius:Number = magnetNode.magneticData.radius + magneticNode.magneticData.radius;
			
			var radians:Number = Math.atan2(magneticNode.spatial.y - magnetNode.spatial.y, magneticNode.spatial.x - magnetNode.spatial.x);
			radians += Math.PI;
			
			if(isAttracted(magnetNode.magneticData.polarity, magneticNode.magneticData.polarity))
			{
				radians += Math.PI;
			}
			
			var strength:Number;
			
			if(distance < 20)
			{
				strength = magnetNode.magnet.strength * (distance / totalRadius);
			}
			else
			{
				strength = magnetNode.magnet.strength;
			}
			
			magnetNode.motion.velocity.x = Math.cos(radians) * strength;
			magnetNode.motion.velocity.y = Math.sin(radians) * strength;
		}
		
		private function isAttracted(polarity1:Number, polarity2:Number):Boolean
		{
			if(polarity1 == 0 || polarity2 == 0) return false;
			if(polarity1 > 0 && polarity2 > 0) return false;
			if(polarity1 < 0 && polarity2 < 0) return false;
			return true;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			this._magnetics = systemManager.getNodeList(MagneticNode);
			this._magnets = systemManager.getNodeList(MagnetNode);
			
			this._magnets.nodeAdded.add(nodeAdded);
			for(var node:MagnetNode = this._magnets.head; node; node = node.next)
			{
				nodeAdded(node);
			}	
		}
		
		private function nodeAdded(node:MagnetNode):void
		{
			node.magneticData.polarityChanged.add(polarityChanged);
			polarityChanged(node.magneticData, NaN);
		}
		
		private function polarityChanged(magneticData:MagneticData, previous:Number):void
		{
			if(magneticData.componentManagers.length == 1)
			{
				var entity:Entity = magneticData.componentManagers[0];
				
				if(magneticData.polarity >= 0)
				{
					MotionControl(entity.get(MotionControl)).lockInput = false;
				}
				
				var child:Entity = EntityUtils.getChildById(entity, "pulse");
				
				if(magneticData.polarity != 0)
				{
					if(!child)
					{
						var shape:Shape = new Shape();
						var container:DisplayObjectContainer = Display(entity.get(Display)).displayObject.parent;
						container.addChildAt(shape, 0);
						child = EntityUtils.createSpatialEntity(entity.group, shape);
						child.add(new Id("pulse"));
						//MotionUtils.followEntity(child, entity);
						child.add(new FollowTarget(entity.get(Spatial)));
						
						EntityUtils.addParentChild(child, entity);
					}
					
					shape = Display(child.get(Display)).displayObject;
					shape.graphics.clear();
					
					if(magneticData.polarity > 0)
					{
						shape.graphics.beginFill(0xF09642, 0.1);
						shape.graphics.drawCircle(0, 0, magneticData.radius);
						shape.graphics.endFill();
					}
					else if(magneticData.polarity < 0)
					{
						shape.graphics.beginFill(0x37B1F7, 0.1);
						shape.graphics.drawCircle(0, 0, magneticData.radius);
						shape.graphics.endFill();
					}
				}
				else if(child && magneticData.polarity == 0)
				{
					if(child)
					{
						child.group.removeEntity(child);
					}
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MagneticNode);
			systemManager.releaseNodeList(MagnetNode);
			
			this._magnetics = null;
			this._magnets = null;
			
			super.removeFromEngine(systemManager);
		}
	}
}