package game.scenes.arab2.entrance.thiefAttack
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.collider.HazardCollider;
	import game.components.motion.TargetEntity;
	import game.util.CharUtils;
	import game.util.GeomUtils;
	
	public class ThiefAttackSystem extends System
	{
		private var _attackers:NodeList;
		private var _targets:NodeList;
		
		public function ThiefAttackSystem()
		{
			super();
		}
		
		override public function update(time:Number):void
		{
			for(var attacker:ThiefAttackNode = this._attackers.head; attacker; attacker = attacker.next)
			{
				var closetDistanceSquared:Number = Number.MAX_VALUE;
				
				for(var target:ThiefAttackTargetNode = this._targets.head; target; target = target.next)
				{
					var distanceSquared:Number = GeomUtils.distSquared(attacker.attack.startX, attacker.attack.startY, target.spatial.x, target.spatial.y);
					
					if(distanceSquared < attacker.attack._distance * attacker.attack._distance)
					{
						if(distanceSquared < closetDistanceSquared)
						{
							closetDistanceSquared = distanceSquared;
							
							if(attacker.attack._target != target.entity)
							{
								attacker.attack._target = target.entity;
								
								CharUtils.followEntity(attacker.entity, target.entity, new Point());
								FSMControl(attacker.entity.get(FSMControl)).removeState("jump");
								attacker.entity.remove(HazardCollider);
							}
							
						}
					}
				}
				
				if(closetDistanceSquared == Number.MAX_VALUE)
				{
					attacker.attack._target = null;
					TargetEntity(attacker.entity.get(TargetEntity)).target = new Spatial(attacker.attack.startX, attacker.attack.startY);
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._attackers = systemManager.getNodeList(ThiefAttackNode);
			this._targets = systemManager.getNodeList(ThiefAttackTargetNode);
			
			for(var node:ThiefAttackNode = this._attackers.head; node; node = node.next)
			{
				this.attackNodeAdded(node);
			}
			this._attackers.nodeAdded.add(this.attackNodeAdded);
			
			this._targets.nodeRemoved.add(targetNodeRemoved);
		}
		
		private function targetNodeRemoved(node:ThiefAttackTargetNode):void
		{
			for(var attacker:ThiefAttackNode = this._attackers.head; attacker; attacker = attacker.next)
			{
				if(attacker.attack._target == node.entity)
				{
					attacker.attack._target = null;
					TargetEntity(attacker.entity.get(TargetEntity)).target = new Spatial(attacker.attack.startX, attacker.attack.startY);
				}
			}
		}
		
		private function attackNodeAdded(node:ThiefAttackNode):void
		{
			node.entity.add(new TargetEntity());
			node.attack.startX = node.spatial.x;
			node.attack.startY = node.spatial.y;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(ThiefAttackNode);
			systemManager.releaseNodeList(ThiefAttackTargetNode);
			
			this._attackers = null;
			this._targets = null;
		}
	}
}