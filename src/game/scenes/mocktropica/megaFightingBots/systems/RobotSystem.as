package game.scenes.mocktropica.megaFightingBots.systems
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.easing.Expo;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.sound.SoundType;
	import game.scene.SceneSound;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	import game.scenes.mocktropica.megaFightingBots.components.ArenaRobot;
	import game.scenes.mocktropica.megaFightingBots.components.RobotSounds;
	import game.scenes.mocktropica.megaFightingBots.components.RobotStats;
	import game.scenes.mocktropica.megaFightingBots.components.Arena;
	import game.scenes.mocktropica.megaFightingBots.nodes.ArenaNode;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	public class RobotSystem extends ListIteratingSystem
	{
		public function RobotSystem($container:DisplayObjectContainer, $group:MegaFightingBots)
		{
			_sceneGroup = $group;
			_container = $container;
			super(ArenaNode, updateNode);
		}
		
		protected function updateNode($node:ArenaNode, $time:Number):void{
			_node = $node;
			// update each robot in arena
			for each(var robotEntity:Entity in $node.arena.robots){
				var robot:ArenaRobot = robotEntity.get(ArenaRobot);
				var display:MovieClip = Display(robotEntity.get(Display)).displayObject as MovieClip;
				var spatial:Spatial = robotEntity.get(Spatial);
				
				var coord:Array;
				var nX:Number;
				var nY:Number;
				
				/**
				 * INIT ROBOT --------------------------------------
				 * Set initial properties of the robot
				 * NOTE: Only runs once
				 */
				if(robot.initted == false){
					initRobot(robot, robotEntity);
				}
				
				// PATCH: Update Parts - timeline system seems to mess with the parts on occasion - this will override that every frame
				updateParts(robot);
				
				/**
				 * MOVEMENT ----------------------------------------
				 * This block of code below handles the movement of the robot
				 */
				// if bot is not moving and has a path, start moving!
				
				if(robot.chargeDir == null && robot.knockDir == null){
					if(robot.moving == false && robot.path.length > 0 && robot.stunned == false && !robot.freeze){
						robot.atDestination = false;
						coord = robot.path.pop();
						
						nX = ((coord[1]*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.x;
						nY = ((coord[0]*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.y;
						
						// face robot
						if(new Point(coord[1],coord[0]) == robot.moveCoord){
							faceRobot(robot, "down");
						} else {
							if(coord[1] > robot.moveCoord.x){
								faceRobot(robot, "right");
							} else if(coord[1] < robot.moveCoord.x){
								faceRobot(robot, "left");
							}
							if(coord[0] > robot.moveCoord.y){
								faceRobot(robot, "down");
							} else if(coord[0] < robot.moveCoord.y){
								faceRobot(robot, "up");
							}
						}
						
						robot.moveCoord = new Point(coord[1], coord[0]);
						
						var moveSpeed:Number;
						
						if(robot.energyExhausted){
							moveSpeed = 0.85;
						} else {
							moveSpeed = robot.speed;
						}
						
						robot.moveTween = new TweenLite(spatial, moveSpeed, {x:nX, y:nY, onComplete:finishMove, onCompleteParams:[robot, display, robotEntity], ease:Linear.easeNone});
						robot.moving = true;
						
						// start walk animation
						//display["botMC"].play();
						
						// update animation
						updateAnimation(robot, "walk");
						
						if(robot.dustEmitter.state != 1){
							robot.dustEmitter.dustOn();
						}
						
						if(robot.playerRobot){
							RobotSounds(robotEntity.get(RobotSounds)).walk();
						}
						
					} else if(robot.path.length == 0 && robot.stunned == false){
						robot.atDestination = true;
					}
				} else if(robot.charging == false || robot.stunned == false){
					/**
					 * CHARGING/KNOCKED ------------------------------------
					 */
					// clear pathfinding / or save it
					robot.path = [];
					
					// create 2 squares of charge path
					var square1:Point;
					var square2:Point;
					
					var dir:String;
					if(robot.chargeDir != null){
						dir = robot.chargeDir;
						robot.savedDir = robot.chargeDir;
					} else if(robot.knockDir != null){
						dir = robot.knockDir;
					}
					
					switch(dir){
						case "right":
							if(robot.knockDir == null){
								faceRobot(robot, "right"); // face robot
							}
							square1 = new Point(robot.moveCoord.x + 1, robot.moveCoord.y);
							square2 = new Point(robot.moveCoord.x + 2, robot.moveCoord.y);
							break;
						case "left":
							if(robot.knockDir == null){
								faceRobot(robot, "left"); // face robot
							}
							square1 = new Point(robot.moveCoord.x - 1, robot.moveCoord.y);
							square2 = new Point(robot.moveCoord.x - 2, robot.moveCoord.y);
							break;
						case "down":
							if(robot.knockDir == null){
								faceRobot(robot, "down"); // face robot
							}
							square1 = new Point(robot.moveCoord.x, robot.moveCoord.y + 1);
							square2 = new Point(robot.moveCoord.x, robot.moveCoord.y + 2);
							break;
						case "up":
							if(robot.knockDir == null){
								faceRobot(robot, "up");; // face robot
							}
							square1 = new Point(robot.moveCoord.x, robot.moveCoord.y - 1);
							square2 = new Point(robot.moveCoord.x, robot.moveCoord.y - 2);
							break;
					}
					
					var wallCoord:Point;
					var wallImpact:Boolean = false;
					var moveSpeedFactor:int;
					
					// check for wall impacts
					if($node.arena.grid[square1.y][square1.x] == 0){
						// square1 is a wall - thus stop
						wallCoord = square1;
						
						// go half way into wall
						coord = [robot.moveCoord.y, robot.moveCoord.x];
						moveSpeedFactor = 4;
						
					} else if($node.arena.grid[square2.y][square2.x] == 0){
						// square 2 is a wall - thus stop
						wallCoord = square2;
						
						coord = [square1.y, square1.x];
						moveSpeedFactor = 2;
					} else {
						coord = [square2.y, square2.x];
						moveSpeedFactor = 1;
					}
					
					// tween to impact point/finish point
					nX = ((coord[1]*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.x;
					nY = ((coord[0]*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.y;
					
					if(wallCoord != null){
						var wX:Number = ((wallCoord.x*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.x;
						var wY:Number = ((wallCoord.y*$node.arena.cellSize)+$node.arena.cellSize/2)+$node.arena.gridZero.y;
						
						nX = (nX + wX) / 2;
						nY = (nY + wY) / 2;
						
						wallImpact = true;
					}
					
					$node.control.gridTarg.visible = false;
					
					robot.moveCoord = new Point(coord[1], coord[0]);
					
					if(robot.chargeDir != null){
						robot.charging = true;
						// show attack Animation
						updateAnimation(robot, "attackStart", 2);
					}
					
					if(robot.charging == true){
						robot.moveTween = new TweenLite(spatial, 0.3/moveSpeedFactor, {x:nX, y:nY, onComplete:finishCharge, onCompleteParams:[robot, display, wallImpact, $node, robotEntity.get(RobotStats), robotEntity]});
					} else {
						robot.moveTween = new TweenLite(spatial, 0.6/moveSpeedFactor, {x:nX, y:nY, onComplete:finishCharge, onCompleteParams:[robot, display, wallImpact, $node, robotEntity.get(RobotStats), robotEntity]});
					}
					
					// dust
					if(robot.dustEmitter.state != 2 ){
						robot.dustEmitter.chargeDust();
					}
					
					// consume energy
					if(robot.charging == true){
						robot.energyPoints -= 30;
						RobotStats(robotEntity.get(RobotStats)).updateEnergy();
						// play attack sound
						RobotSounds(robotEntity.get(RobotSounds)).attack();
					}
					
					// stop walk sound
					if(robot.playerRobot){
						RobotSounds(robotEntity.get(RobotSounds)).walk(true);
					}
					
					// reset values
					robot.chargeDir = null;
					robot.knockDir = null;
				}

				
				// slowly refill energy
				if($node.arena.gameState == 2){
					RobotStats(robotEntity.get(RobotStats)).rechargeEnergy();
				}
				
				/**
				 * DUST PARTICLES -------------------------------------
				 */
				
				Spatial(robot.dustEntity.get(Spatial)).x = spatial.x;
				Spatial(robot.dustEntity.get(Spatial)).y = spatial.y + 30;
				
				
				/**
				 * HIT DETECTION --------------------------------------
				 * The below block updates the robot's hitCoord (used in hit detection) 
				 * Note: This is separate from movement
				 */
				
				// find the "closest" square that the robot is currently on
				var xIndex:int = Math.floor((spatial.x - $node.arena.gridZero.x) / $node.arena.cellSize);
				var yIndex:int = Math.floor((spatial.y - $node.arena.gridZero.y) / $node.arena.cellSize);
				
				robot.hitCoord = new Point(xIndex,yIndex);
				
				// check robot collisions if charging
				if(robot.charging == true){
					for each(var possibleRobotEntity:Entity in $node.arena.robots){
						var possibleRobot:ArenaRobot = possibleRobotEntity.get(ArenaRobot);
						if(robot != possibleRobot){
							// check collision with robot
							if(robot.hitCoord.equals(possibleRobot.hitCoord)){

								// set robot coordinates/path to point of impact
								robot.moveCoord = robot.hitCoord;
								robot.path = [[robot.moveCoord.y, robot.moveCoord.x]];
								robot.charging = false;
								robot.moving = false;

								// stop and update charge tween to stop
								//robot.moveTween = new TweenLite(spatial, 0.3, {x:nX, y:nY, onComplete:finishCharge, onCompleteParams:[robot, display, wallImpact, $node]});
								robot.moveTween.kill();
								
								// stun both robots for a moment
								stunRobot(robot);
								stunRobot(possibleRobot);
								
								// update animations of robots
								//updateAnimation(robot, "hit", 3);
								updateAnimation(possibleRobot, "hit", 3);
								
								// knock target robot back 2 squares depending on direction of hit
								possibleRobot.moveCoord = possibleRobot.hitCoord; // possible "wierdness with this
								possibleRobot.knockDir = robot.savedDir;
								possibleRobot.hitPoints -= 5*robot.strength;
								RobotStats(possibleRobotEntity.get(RobotStats)).updateHealth();
								
								// flash both robots
								TweenMax.to(display, 0, {colorMatrixFilter:{contrast:1.5, brightness:2}});
								TweenMax.to(display, 0.5, {colorMatrixFilter:{}, onComplete:checkExhaustion, onCompleteParams:[robot, display]});
								
								TweenMax.to(Display(possibleRobotEntity.get(Display)).displayObject, 0, {colorMatrixFilter:{colorize:0xcc3300, amount:0.5, contrast:1.5, brightness:2}});
								TweenMax.to(Display(possibleRobotEntity.get(Display)).displayObject, 0.5, {colorMatrixFilter:{}, onComplete:checkExhaustion, onCompleteParams:[ArenaRobot(possibleRobotEntity.get(ArenaRobot)), Display(possibleRobotEntity.get(Display)).displayObject]});
								
								// position spark at impact point
								var pX:Number = (spatial.x + Spatial(possibleRobotEntity.get(Spatial)).x) / 2;
								var pY:Number = (spatial.y + Spatial(possibleRobotEntity.get(Spatial)).y) / 2;
								
								Spatial($node.arena.sparkEntity.get(Spatial)).x = Spatial(possibleRobotEntity.get(Spatial)).x;
								Spatial($node.arena.sparkEntity.get(Spatial)).y = Spatial(possibleRobotEntity.get(Spatial)).y;
								
								//shakeTween(Display(_sceneGroup.getEntityById("arena").get(Display)).displayObject, 2);
								
								$node.arena.sparkEmitter.spark();
								
								// play hit sound
								RobotSounds(robotEntity.get(RobotSounds)).hit();
							}
						}
					}
				}
				
				// check win conditions 
				if(robot.hitPoints <= 0){
					// if robot is player bot, not final round or day2 cheat is on
					if(robot.playerRobot || ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).wins < 1 || _sceneGroup.cheatOn == true){
						robotLose(robotEntity);
						$node.arena.gameState = 3;
						// win other robots
						for each(var robotEntityC:Entity in $node.arena.robots){
							robotWin(robotEntityC);
						}
					} else {
						// if enemy robot && final round, cheat and use megacoin
						ArenaRobot($node.arena.cpuRobot.get(ArenaRobot)).hitPoints += 100;
						RobotStats($node.arena.cpuRobot.get(RobotStats)).updateHealth();
						
						// stop robots and play coin animation & vignette
						faceRobot(ArenaRobot($node.arena.cpuRobot.get(ArenaRobot)), "down");
						updateAnimation($node.arena.cpuRobot.get(ArenaRobot), "coin");
						
						// play coinUp sound
						RobotSounds(robotEntity.get(RobotSounds)).coinUp();
						
						_sceneGroup.playCoinUp();
						Timeline(_sceneGroup.coinUp.get(Timeline)).handleLabel("coinEnd", endCoinFreeze, true);
						
						//ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).freeze = true;
						//ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).path = [];

						//ArenaRobot($node.arena.cpuRobot.get(ArenaRobot)).freeze = true;
						//ArenaRobot($node.arena.cpuRobot.get(ArenaRobot)).path = [];

						//Timeline(ArenaRobot($node.arena.cpuRobot.get(ArenaRobot)).frontEntity.get(Timeline)).gotoAndPlay("coin");
					}
				}
			}
		}
		
		private function endCoinFreeze():void{
			// end coin freeze
			ArenaRobot(_node.arena.playerRobot.get(ArenaRobot)).freeze = false;
			ArenaRobot(_node.arena.cpuRobot.get(ArenaRobot)).freeze = false;
		}
		
		private function checkExhaustion($robot:ArenaRobot, $display:DisplayObject):void{
			/*if($robot.energyExhausted){
				if($robot.colorTimeline){
					$robot.colorTimeline.clear();
				} else {
					$robot.colorTimeline = new TimelineMax({repeat:-1});
				}
				
				$robot.colorTimeline.append(new TweenMax($display, 0.3, {colorMatrixFilter:{colorize:0xff0000, amount:0.8}}));
				$robot.colorTimeline.append(new TweenMax($display, 0.3, {colorMatrixFilter:{}}));
			}*/
		}
		
		private function initRobot($robot:ArenaRobot, $robotEntity:Entity):void{
			// reset positioning
			var nX:Number = (($robot.startPoint.x*_node.arena.cellSize)+_node.arena.cellSize/2)+_node.arena.gridZero.x;
			var nY:Number = (($robot.startPoint.y*_node.arena.cellSize)+_node.arena.cellSize/2)+_node.arena.gridZero.y;
			
			Spatial($robotEntity.get(Spatial)).x = nX;
			Spatial($robotEntity.get(Spatial)).y = nY;
			
			updateParts($robot);
			faceRobot($robot,"down");
			$robot.initted = true;
		}
		
		private function updateParts($robot:ArenaRobot):void{
			// init parts of front facing robot
			Display($robot.frontEntity.get(Display)).displayObject["body"].gotoAndStop($robot.body);
			Display($robot.frontEntity.get(Display)).displayObject["rArm"].gotoAndStop($robot.arms);
			Display($robot.frontEntity.get(Display)).displayObject["lArm"].gotoAndStop($robot.arms);
			Display($robot.frontEntity.get(Display)).displayObject["rLeg"].gotoAndStop($robot.legs);
			Display($robot.frontEntity.get(Display)).displayObject["lLeg"].gotoAndStop($robot.legs);
			
			// init parts of back facing robot
			Display($robot.backEntity.get(Display)).displayObject["body"].gotoAndStop($robot.body);
			Display($robot.backEntity.get(Display)).displayObject["rArm"].gotoAndStop($robot.arms);
			Display($robot.backEntity.get(Display)).displayObject["lArm"].gotoAndStop($robot.arms);
			Display($robot.backEntity.get(Display)).displayObject["rLeg"].gotoAndStop($robot.legs);
			Display($robot.backEntity.get(Display)).displayObject["lLeg"].gotoAndStop($robot.legs);
			
			// init parts of left facing robot
			Display($robot.leftEntity.get(Display)).displayObject["bodyS"].gotoAndStop($robot.body);
			Display($robot.leftEntity.get(Display)).displayObject["armS"].gotoAndStop($robot.arms);
			Display($robot.leftEntity.get(Display)).displayObject["legS"].gotoAndStop($robot.legs);
			
			// init parts of right facing robot
			Display($robot.rightEntity.get(Display)).displayObject["bodyS"].gotoAndStop($robot.body);
			Display($robot.rightEntity.get(Display)).displayObject["armS"].gotoAndStop($robot.arms);
			Display($robot.rightEntity.get(Display)).displayObject["legS"].gotoAndStop($robot.legs);
		}
		
		private function faceRobot($robot:ArenaRobot, $direction:String):void{
			// only change if there is a new direction
			if($robot.currentFaceDir != $direction){
				// start by hiding all facings
				Display($robot.frontEntity.get(Display)).visible = false;
				Display($robot.backEntity.get(Display)).visible = false;
				Display($robot.leftEntity.get(Display)).visible = false;
				Display($robot.rightEntity.get(Display)).visible = false;
				
				// stop animation on currentFaceEntity
				if($robot.currentFaceEntity){
					Timeline($robot.currentFaceEntity.get(Timeline)).gotoAndStop(1);
				}
				
				// only show correct facing (while others are hidden)
				switch($direction){
					case "down":
						Display($robot.frontEntity.get(Display)).visible = true;
						$robot.currentFaceEntity = $robot.frontEntity;
						break;
					case "up":
						Display($robot.backEntity.get(Display)).visible = true;
						$robot.currentFaceEntity = $robot.backEntity;
						break;
					case "left":
						Display($robot.leftEntity.get(Display)).visible = true;
						$robot.currentFaceEntity = $robot.leftEntity;
						break;
					case "right":
						Display($robot.rightEntity.get(Display)).visible = true;
						$robot.currentFaceEntity = $robot.rightEntity;
						break;
				}
				
				
				
				// carry over animation from robot.currentAnimation
				//trace("carrying over currentAnimation:"+$robot.currentAnimation+" to timeline:"+Timeline($robot.currentFaceEntity.get(Timeline)));
				Timeline($robot.currentFaceEntity.get(Timeline)).gotoAndPlay($robot.currentAnimation);
				
				//trace(TimelineMaster($robot.currentFaceEntity.get(TimelineMaster)).
				// set new currentFaceDir
				$robot.currentFaceDir = $direction;
			}
		}
		
		private function updateAnimation($robot:ArenaRobot, $animation:String, $mood:int = 1):void{
			// set current animation
			$robot.currentAnimation = $animation;
			$robot.mood = $mood;
			// set animation on timeline
			if(!$robot.lost && !$robot.win){
				try{
					Timeline($robot.currentFaceEntity.get(Timeline)).gotoAndPlay($robot.currentAnimation);
					if($robot.currentFaceDir == "down"){
						Display($robot.currentFaceEntity.get(Display)).displayObject["body"]["face"].gotoAndStop($robot.mood);
					} else if($robot.currentFaceDir == "left" || $robot.currentFaceDir == "right"){
						Display($robot.currentFaceEntity.get(Display)).displayObject["bodyS"]["face"].gotoAndStop($robot.mood);
					}
				} catch(e:Error){
					trace(e.message);
				}
			}
		}
		
		private function finishMove($robot:ArenaRobot, $display:MovieClip, $robotEntity):void{
			$robot.moving = false;
			if($robot.atDestination == true){
				//$display["botMC"].gotoAndPlay("idle");
				$robot.dustEmitter.dustOff();
				updateAnimation($robot, "idle");
				if($robot.playerRobot){
					RobotSounds($robotEntity.get(RobotSounds)).walk(true);
				}
			}
			
		}
		
		private function finishCharge($robot:ArenaRobot, $display:MovieClip, $wallImpact:Boolean, $node:ArenaNode, $stats:RobotStats, $robotEntity:Entity):void{
			// set destination and turn off dust
			if($robot.atDestination == true){
				//$display["botMC"].gotoAndPlay("idle");
				$robot.dustEmitter.dustOff();
				updateAnimation($robot, "idle");
			}
			// if attacking, play attacking animation
			if($robot.stunned == false){
				// show attack Animation
				updateAnimation($robot, "attackFinish");
			}
			// if you hit wall, shake wall and play animation
			if($wallImpact == true){
				if($robot.charging == true){
					// intense shaking
					shakeTween(Display(_sceneGroup.getEntityById("arena").get(Display)).displayObject, 3, 5, Arena(_sceneGroup.getEntityById("arena").get(Arena)).origPoint);
				} else {
					// not so intense shaking
					shakeTween(Display(_sceneGroup.getEntityById("arena").get(Display)).displayObject, 1, 2, Arena(_sceneGroup.getEntityById("arena").get(Arena)).origPoint);
				}
				
				updateAnimation($robot, "shock", 3);
				
				stunRobot($robot);
				
				// damage robot
				$robot.hitPoints -= 15;
				$stats.updateHealth();
					
				//TweenMax.to($display, 0, {colorMatrixFilter:{colorize:0xFF0000, amount:0.8, contrast:1.5, brightness:0.5}});
				//TweenMax.to($display, 1, {colorMatrixFilter:{}});
				$node.arena.exciteCrowd();
				
				// play sound
				RobotSounds($robotEntity.get(RobotSounds)).impact();
			}
			$robot.moving = false;
			$robot.atDestination = true;
			$robot.charging = false;
		}
		
		private function stunRobot($robot:ArenaRobot, $duration:Number = 0.5):void{
			// stun robot
			$robot.stunned = true;
			$robot.stunTimerEvent = SceneUtil.addTimedEvent(_sceneGroup, new TimedEvent($duration, 1, unStun, true));
			function unStun():void{
				$robot.stunned = false;
			}
			// unstun after a second or so
		}
		
		private function shakeTween(item:DisplayObject, repeatCount:int, $intensity:Number = 5, $origPoint:Point = null):void
		{
			try{
				TweenMax.to(item,0.1,{repeat:repeatCount-1, y:item.y+(1+Math.random()*$intensity), x:item.x+(1+Math.random()*$intensity), ease:Expo.easeInOut});
				TweenMax.to(item,0.1,{y:item.y, x:item.x, delay:(repeatCount+1) * .1, ease:Expo.easeInOut, onComplete:reset});
			} catch (e:Error) {
				reset();
			}
			
			function reset():void{
				if($origPoint != null){
					item.x = $origPoint.x;
					item.y = $origPoint.y;
				}
			}
		}
		
		private function robotWin($robotEntity:Entity):void{
			if(!ArenaRobot($robotEntity.get(ArenaRobot)).lost && !ArenaRobot($robotEntity.get(ArenaRobot)).win){
				// face player and cheer!
				faceRobot($robotEntity.get(ArenaRobot), "down");
				updateAnimation($robotEntity.get(ArenaRobot), "winStart", 4);
				ArenaRobot($robotEntity.get(ArenaRobot)).win = true;
				ArenaRobot($robotEntity.get(ArenaRobot)).path = [];
				ArenaRobot($robotEntity.get(ArenaRobot)).freeze = true;
				RobotStats($robotEntity.get(RobotStats)).winState();
				
				var audio:Audio = AudioUtils.getAudio(_sceneGroup, SceneSound.SCENE_SOUND);
				audio.fadeAll(0, NaN, 1, SoundType.MUSIC);
				
				_sceneGroup.shellApi.triggerEvent("cheer");
				
				// listen for "ko" to finish game screen
				Timeline(ArenaRobot($robotEntity.get(ArenaRobot)).currentFaceEntity.get(Timeline)).handleLabel("ko", finishGame);
				
				// stop all sounds
				RobotSounds($robotEntity.get(RobotSounds)).stopAll();
			}
		}
		
		private function robotLose($robotEntity:Entity):void{
			if(!ArenaRobot($robotEntity.get(ArenaRobot)).lost){
				// face player and break down
				RobotStats($robotEntity.get(RobotStats)).strikePortrait();
				faceRobot($robotEntity.get(ArenaRobot), "down");
				updateAnimation($robotEntity.get(ArenaRobot), "lose", 5);
				trace("ROBOT LOST!");
				ArenaRobot($robotEntity.get(ArenaRobot)).lost = true;
				ArenaRobot($robotEntity.get(ArenaRobot)).path = [];
				ArenaRobot($robotEntity.get(ArenaRobot)).freeze = true;
				RobotStats($robotEntity.get(RobotStats)).loseState();
				
				// play breakDown sound
				RobotSounds($robotEntity.get(RobotSounds)).breakDown();
			}
		}
		
		private function finishGame():void{
			// set values in winLose screen
			_sceneGroup.setWinLose();
			Timeline(_node.arena.ko.get(Timeline)).gotoAndPlay(2);
			Timeline(_node.arena.ko.get(Timeline)).handleLabel("whiteout", resetGame);
		}
		
		private function resetGame():void{
			var finalGame:Boolean = false;
			var playerLost:Boolean = false;
			// reset all data on robots
			for each(var robotEntity:Entity in _node.arena.robots){
				var robot:ArenaRobot = robotEntity.get(ArenaRobot);
				
				if(robot.win){
					robot.wins++;
				}
				
				if(finalGame == true){
					robot.wins = 0;
				}
				
				if(robot.wins >= 2){
					finalGame = true;
					robot.wins = 0;
				}
				
				// reset health/win/lose stats
				
				if(robot.playerRobot && robot.lost){
					playerLost = true;
				}
				
				robot.hitPoints = robot.maxHitPoints;
				robot.energyPoints = robot.maxEnergyPoints;
				robot.win = false;
				robot.lost = false;
				robot.freeze = true;
				RobotStats(robotEntity.get(RobotStats)).updateHealth();
				RobotStats(robotEntity.get(RobotStats)).updateEnergy();
				
				robot.path = [];
				robot.moveCoord = robot.startPoint;
				
				// reset positioning
				var nX:Number = ((robot.startPoint.x*_node.arena.cellSize)+_node.arena.cellSize/2)+_node.arena.gridZero.x;
				var nY:Number = ((robot.startPoint.y*_node.arena.cellSize)+_node.arena.cellSize/2)+_node.arena.gridZero.y;
				
				Spatial(robotEntity.get(Spatial)).x = nX;
				Spatial(robotEntity.get(Spatial)).y = nY;
				
				// reset animation
				updateAnimation(robotEntity.get(ArenaRobot), "idle", 1);
			}
			
			if(finalGame == true){
				for each(robotEntity in _node.arena.robots){
					robot = robotEntity.get(ArenaRobot);
					robot.wins = 0;
				}
			}
			
			// reset arena
			_node.arena.gameState = 0;
			_node.arena.cameraFlashes.visible = false;
			
			if(finalGame){
				_node.arena.round = 0;
				_sceneGroup.gameOver(playerLost);
			} else {
				_sceneGroup.newRound();
			}
			
		}
		
		private var _node:ArenaNode;
		protected var _container:DisplayObjectContainer;
		protected var _sceneGroup:MegaFightingBots;
	}
}