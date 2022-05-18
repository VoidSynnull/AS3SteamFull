package game.scenes.virusHunter.brain.systems
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.scenes.virusHunter.brain.components.BrainBoss;
	import game.scenes.virusHunter.brain.components.IKSegment;
	import game.scenes.virusHunter.brain.components.NeuronReach;
	import game.scenes.virusHunter.brain.nodes.IKReachNode;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class NeuronReachSystem extends IKReachSystem
	{
		public function NeuronReachSystem($container:DisplayObjectContainer, $group:Group)
		{
			super($container, $group);
		}
		
		override protected function updateNode($node:IKReachNode, $time:Number):void{
			
			var bossEntity:Entity = _sceneGroup.getEntityById("bossVirus");
			var brainBoss:BrainBoss;
			
			if(bossEntity)
			{
				brainBoss = bossEntity.get(BrainBoss);
			}
			
			for each(var ikReachEntity:Entity in $node.ikReachBatch.ikReachBatch){
				var ikReach:NeuronReach = NeuronReach(ikReachEntity.get(NeuronReach));
				
				var damageTarg:DamageTarget = ikReachEntity.get(DamageTarget);
				var brainBossOnNeuron:Boolean = false;
				
				if(brainBoss)
				{
					if(brainBoss.onNeuron == ikReach.neuron)
					{
						brainBossOnNeuron = true;
					}
				}
				
				if(damageTarg.isHit == true && !brainBossOnNeuron && ikReach.hitWaitTime <= 0)
				{
					ikReach.hitWaitTime = ikReach.minHitWaitTime;
					
					if(!ikReach.reaching){
						// pulse neuron to let it know that it's been "charged"
						TweenMax.to(ikReach.display, 0, {colorMatrixFilter:{contrast:1.5, brightness:2}});
						TweenMax.to(ikReach.display, 1, {colorMatrixFilter:{}});
						
						ikReach.reaching = true;
						ikReach.targetEntity = _sceneGroup.getEntityById("player");
						ikReach.reverting = false;
						ikReach.reachPoint = new Point(ikReach.display["ikNode_1"].x, ikReach.display["ikNode_1"].y);
						ikReach.connectedToPoint = null;
						ikReach.pauseMotion = false;
						ikReach.connectedTo = null;
					} else {
						TweenMax.to(ikReach.display, 0, {colorMatrixFilter:{contrast:1, brightness:0.5}});
						TweenMax.to(ikReach.display, 1, {colorMatrixFilter:{}});
						
						ikReach.reaching = false;
						ikReach.revertToOriginal();
					}
				}
				
				damageTarg.isHit = false;
				
				if(ikReach.hitWaitTime > 0)
				{
					ikReach.hitWaitTime -= $time;
				}
				
				if(ikReach.reaching == true && !brainBossOnNeuron)
				{
					if(!ikReach.pauseMotion){
						_targetPoint = ikReach.reachPoint;
						
						var targetPoint:Point 
						if(!ikReach.connectedToPoint){
							// need to set targetDisplay to the playerShip
							ikReach.targetEntity = _sceneGroup.getEntityById("player");
							
							var targetDisplay:Display = ikReach.targetEntity.get(Display);
							targetPoint = localToLocal(targetDisplay.displayObject, ikReach.display);
						} else {
							// connect to _connectedPoint (to other neuron)
							targetPoint = ikReach.connectedToPoint;
							
							var audio:Audio = ikReachEntity.get( Audio )
							if( !audio )
							{
								audio = new Audio();
								ikReachEntity.add( audio );
							}
							if( audio.isPlaying( SoundManager.EFFECTS_PATH + ELECTRIC_ZAP ))
							{
								audio.play( SoundManager.EFFECTS_PATH + ELECTRIC_ZAP, false );
							}
						}
						
						if(_targetPoint != targetPoint){
							_targetPoint = targetPoint;
							var tween:TweenLite = new TweenLite(ikReach.reachPoint, 1, {x:_targetPoint.x, y:_targetPoint.y});
						}
	
						var target:Point = reach(ikReach.segments[0], ikReach.reachPoint.x, ikReach.reachPoint.y);
						
						// get targets
						for each(var ikSegment:IKSegment in ikReach.segments)
						{
							target = reach(ikSegment, target.x, target.y);
						}
						
						// position segments
					
						for(var i:int = ikReach.segments.length - 1; i > 0; i--)
						{
							var segmentA:IKSegment = ikReach.segments[i];
							var segmentB:IKSegment = ikReach.segments[i - 1];
							position(segmentB, segmentA);
						}
						
						// check for connecting other neurons
						var connectedNeuron:NeuronReach = nearbyValidNeuron(ikReach, $node);
						
						if(connectedNeuron != null && ikReach.connectedToPoint == null){
							// get point of "head" of neuron
							ikReach.connectedToPoint = localToLocal(connectedNeuron.display, ikReach.display);
							//ikReach.connectedToPoint = ikReach.reachPoint;
							//trace("Connecting to: "+ikReach.connectedToPoint);
							
							ikReach.connectedTo = connectedNeuron;
							ikReach.neuron.connectedNeuron = connectedNeuron.neuron;
							
							connectedNeuron.connectedBy = ikReach;
							
							// tween both Neurons with a glow to show they have connected
							TweenMax.allTo([connectedNeuron.display, ikReach.display], 0, {colorMatrixFilter:{contrast:1.5, brightness:2}});
							TweenMax.allTo([connectedNeuron.display, ikReach.display], 1, {colorMatrixFilter:{}, onComplete:freezeNeuron, onCompleteParams:[ikReach,ikReachEntity]});
							
							// trace bossvirus for testing
							//var bossEntity:Entity = _sceneGroup.getEntityById("bossVirus");
							
						}
					}
					
				} else {
					ikReach.revertToOriginal();
				}
			}
		}
		
		private function freezeNeuron($ikReach:NeuronReach,$ikReachEntity:Entity):void{
			$ikReach.pauseMotion = true;
		
			var audio:Audio = $ikReachEntity.get( Audio )
			if( !audio )
			{
				audio = new Audio();
				$ikReachEntity.add( audio );
			}
			audio.play( SoundManager.EFFECTS_PATH + ELECTRIC_ZAP, false );
		}
		
		private function nearbyValidNeuron($ikReach:NeuronReach, $ikReachNode:IKReachNode):NeuronReach{
			/**
			 * scan all NeuronReach armatures in the node to see if the foot of $ikReach is "touching" a head of a neuron
			 * if so, return it
			 */
			
			for each(var ikReachEntity:Entity in $ikReachNode.ikReachBatch.ikReachBatch){
				var ikReach:NeuronReach = NeuronReach(ikReachEntity.get(NeuronReach));
				if(ikReach != $ikReach && ikReach != $ikReach.connectedBy){
					var headPoint:Point = new Point(ikReach.display["ikNode_16"].x, ikReach.display["ikNode_16"].y);
					
					var localFootPoint:Point = localToLocal($ikReach.display["ikNode_0"], ikReach.display["ikNode_16"]);
					
					if(pointDistance(localFootPoint, headPoint) < 120){
						return ikReach;
					}
				}
			}
			
			return null;
		}
		
		private function pointDistance($fr:Point, $to:Point):Number{
			return Math.sqrt(($fr.x - $to.x)*($fr.x - $to.x) + ($fr.y - $to.y)*($fr.y - $to.y));
		}
		
		private var _neuronInMotion:NeuronReach;
		private static const ELECTRIC_ZAP:String = "electric_zap_03.mp3";
	}
}