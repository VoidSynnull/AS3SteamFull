package game.scenes.deepDive2.medusaArea.systems 
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.deepDive2.medusaArea.MedusaArea;
	import game.scenes.deepDive2.medusaArea.nodes.EelNode;
	import game.scenes.deepDive2.medusaArea.nodes.HydromedusaNode;
	import game.scenes.deepDive2.medusaArea.nodes.MedusaSwitchNode;
	import game.systems.SystemPriorities;
	
	public class MedusaAreaSystem extends System
	{
		private var _medusas:NodeList;
		private var _eels:NodeList;
		private var _switches:NodeList;
		private var player:Entity;
		private var pSpatial:Spatial;
		private var hydroSpeed:Number = 4;
		
		private var vx:Number;
		private var vy:Number;
		private var maxSpeed:Number = 200;
		
		private var dx:Number;
		private var dy:Number;
		private var dist:Number;
		
		private var switchLimit:Number;
		
		private var currSwitch:Entity;
		private var eel:EelNode;
		
		public function MedusaAreaSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_medusas = systemManager.getNodeList( HydromedusaNode );
			_eels = systemManager.getNodeList( EelNode );
			_switches = systemManager.getNodeList( MedusaSwitchNode );
			player = MedusaArea(super.group).player;
			pSpatial = MedusaArea(super.group).player.get(Spatial);
			eel = _eels.head;
			//_medusas.head.hydromedusa.target = pSpatial;
		}
		
		override public function update( time:Number ):void
		{
			var medusa:HydromedusaNode;
			var sw:MedusaSwitchNode;
			
			for(medusa = _medusas.head; medusa; medusa = medusa.next) {
				
				if(medusa.hydromedusa.active){
					
					dx = medusa.spatial.x - medusa.hydromedusa.target.x;
					dy = medusa.spatial.y - medusa.hydromedusa.target.y;
					dist = Math.sqrt(dx * dx + dy * dy);
					
					if(dist < 400 && !medusa.hydromedusa.stung){
						vx = (medusa.hydromedusa.target.x - medusa.spatial.x) * .8;
						vy = (medusa.hydromedusa.target.y - medusa.spatial.y) * .8;
						
						if(vx > 0){
							if(medusa.motion.velocity.x < vx){
								if(medusa.motion.velocity.x < 0){
									medusa.motion.velocity.x += hydroSpeed * 1.5;
								}else{
									medusa.motion.velocity.x += hydroSpeed;
								}
							}
						}else if(vx < 0){
							if(medusa.motion.velocity.x > vx){
								if(medusa.motion.velocity.x > 0){
									medusa.motion.velocity.x -= hydroSpeed * 1.5;
								}else{
									medusa.motion.velocity.x -= hydroSpeed;
								}
							}
						}
						if(vy > 0){
							if(medusa.motion.velocity.y < vy){
								if(medusa.motion.velocity.y < 0){
									medusa.motion.velocity.y += hydroSpeed * 1.5;
								}else{
									medusa.motion.velocity.y += hydroSpeed;
								}
							}
						}else if(vy < 0){
							if(medusa.motion.velocity.y > vy){
								if(medusa.motion.velocity.y > 0){
									medusa.motion.velocity.y -= hydroSpeed * 1.5;
								}else{
									medusa.motion.velocity.y -= hydroSpeed;
								}
							}
						}
						
						medusa.motion.rotation = medusa.motion.velocity.x / 10;
						
						if(medusa.motion.velocity.x > maxSpeed){
							medusa.motion.velocity.x = maxSpeed;
						}else if(medusa.motion.velocity.x < -maxSpeed){
							medusa.motion.velocity.x = -maxSpeed;
						}
						
						if(medusa.motion.velocity.y > maxSpeed){
							medusa.motion.velocity.y = maxSpeed;
						}else if(medusa.motion.velocity.y < -maxSpeed){
							medusa.motion.velocity.y = -maxSpeed;
						}
						
						if(medusa.hydromedusa.statementWait){
							medusa.hydromedusa.statementWait = false;
							MedusaArea(super.group).runStatement();
						}
					}else if(medusa.sleep.sleeping && !medusa.hydromedusa.stung){
						medusa.spatial.x = medusa.hydromedusa.pos.x;
						medusa.spatial.y = medusa.hydromedusa.pos.y;
						medusa.motion.velocity.x = 0;
						medusa.motion.velocity.y = 0;
					}else{
						if(medusa.motion.velocity.x > 0){
							medusa.motion.velocity.x -= 1;
						}else if(medusa.motion.velocity.x < 0){
							medusa.motion.velocity.x += 1;
						}
						
						if(medusa.motion.velocity.y > 0){
							medusa.motion.velocity.y -= 1;
						}else if(medusa.motion.velocity.y < 0){
							medusa.motion.velocity.y += 1;
						}
						
						if(medusa.motion.rotation > 0){
							medusa.motion.rotation -= .1;
						}else if(medusa.motion.rotation < 0){
							medusa.motion.rotation += .1;
						}
					}
					
					if(!medusa.hydromedusa.foundSwitch){
						for(sw = _switches.head; sw; sw = sw.next) {
							if(!sw.medusaSwitch.open){
								//trace(sw.spatial.x);
								dx = medusa.spatial.x - sw.spatial.x;
								dy = medusa.spatial.y - sw.spatial.y;
								dist = Math.sqrt(dx * dx + dy * dy);
								
								if(sw.medusaSwitch.idNum == 7){
									switchLimit = 150;
								}else{
									switchLimit = 75;
								}
								
								if(dist < switchLimit){
									medusa.hydromedusa.target = sw.spatial;
									medusa.hydromedusa.foundSwitch = true;
									currSwitch = sw.entity;
								}
							}
						}
						
						dx = medusa.spatial.x - pSpatial.x;
						dy = medusa.spatial.y - pSpatial.y;
						dist = Math.sqrt(dx * dx + dy * dy);
						
						if(!medusa.hydromedusa.stung){
							if(dist < 100){
								medusa.motion.velocity.x *= -1;
								medusa.motion.velocity.y *= - 1;
								medusa.hydromedusa.stung = true;
								MedusaArea(super.group).startFrySub(medusa.entity);
							}
						}
					}else{
						dx = medusa.spatial.x - medusa.hydromedusa.target.x;
						dy = medusa.spatial.y - medusa.hydromedusa.target.y;
						dist = Math.sqrt(dx * dx + dy * dy);
						
						if(dist < 4){
							medusa.hydromedusa.active = false;
							medusa.motion.velocity.x = 0;
							medusa.motion.velocity.y = 0;
							MedusaArea(super.group).runSwitch(currSwitch);
						}
					}
				}
			}
			
			//eel
			if(eel.eel.facingRight){
				//if(Math.abs(eel.spatial.y - pSpatial.y) < 100 && pSpatial.x > eel.eel.left && eel.spatial.x < pSpatial.x){
					//eel.eel.attacking = true;
			//	}
				if(eel.spatial.x < eel.eel.right){
					if(eel.eel.attacking){
						eel.spatial.x += eel.eel.speed*2;
					}else{
						eel.spatial.x += eel.eel.speed;
					}
				}else{
					eel.eel.facingRight = false;
					eel.spatial.scaleX = 1;
					if(eel.eel.attacking){
						eel.eel.attacking = false;
					}
				}
			}else{
				//if(Math.abs(eel.spatial.y - pSpatial.y) < 100 && pSpatial.x > eel.eel.left && eel.spatial.x > pSpatial.x){
					//eel.eel.attacking = true;
				//}
				if(eel.spatial.x > eel.eel.left){
					if(eel.eel.attacking){
						eel.spatial.x -= eel.eel.speed*2;
					}else{
						eel.spatial.x -= eel.eel.speed;
					}
				}else{
					eel.eel.facingRight = true;
					eel.spatial.scaleX = -1;
					if(eel.eel.attacking){
						eel.eel.attacking = false;
					}
				}
			}
			//hit test
			if(!eel.eel.stung){
				if(Math.abs(eel.spatial.y - pSpatial.y) < 70 && Math.abs(eel.spatial.x - pSpatial.x) < 100){
					eel.eel.stung = true;
					MedusaArea(super.group).eelShock(eel.entity);
				}
			}
			if(eel.spatial.scaleX > 0){
				eel.spatialOffset.scaleX = 0.3 - (Math.sin(eel.eel.angle) * .05);
			}else{
				eel.spatialOffset.scaleX = -0.3 + (Math.sin(eel.eel.angle) * .05);
			}
			
			eel.eel.angle += .2;
			
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( HydromedusaNode );
			systemsManager.releaseNodeList( EelNode );
			systemsManager.releaseNodeList( MedusaSwitchNode );
			_medusas = null;
			_eels = null;
			_switches = null;
		}
	}
}




