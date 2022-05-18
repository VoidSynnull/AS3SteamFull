package game.scenes.survival2.beaverDen.systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.survival2.beaverDen.components.BeaverComponent;
	import game.scenes.survival2.beaverDen.components.DamControlComponent;
	import game.scenes.survival2.beaverDen.components.LeakComponent;
	import game.scenes.survival2.beaverDen.nodes.BeaverNode;
	import game.scenes.survival2.beaverDen.nodes.DamControlNode;
	import game.scenes.survival2.beaverDen.nodes.LeakNode;
	import game.scenes.survival2.beaverDen.nodes.TreeLogNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class BeaverSystem extends GameSystem
	{
		private const HIT:String = "hit";
		private const TARGET_DELTA:int = 25;
		
		private var _damControlNode:DamControlNode;
		private var _logList:NodeList;
		private var _leakList:NodeList;
		private var _dispatched:Boolean = false;
		
		
		public var victory:Signal = new Signal();
		
		public function BeaverSystem()
		{
			super( BeaverNode, updateNode );
			super._defaultPriority = SystemPriorities.checkCollisions;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_damControlNode = systemManager.getNodeList( DamControlNode ).head as DamControlNode;
			_leakList = systemManager.getNodeList( LeakNode );
			_logList = systemManager.getNodeList( TreeLogNode );
			
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( TreeLogNode );
			super.removeFromEngine( systemManager );
		}
		
		private function updateNode( node:BeaverNode, time:Number ):void
		{
			var angle:Number;
			var beaver:BeaverComponent = node.beaver;
			var degrees:Number;
			var delta:Number;
			var dx:Number;
			var dy:Number;
			var motion:Motion = node.motion;
			var number:Number;
			var spatial:Spatial = node.spatial;
			var targetDistance:Number;
			var damControl:DamControlComponent = _damControlNode.damControl
			
			if( damControl.waterSpatial.y > beaver.WATER_DEFEAT_Y && !beaver.isDefeated && beaver.state != beaver.HURT )
			{
				if( !damControl.victory )
				{
					damControl.victory = true;
					SceneUtil.lockInput( group );
				}

				beaver.isDefeated = true;
				beaver.state = beaver.GRUMPY;
				motion.zeroMotion();
				beaver.isMoving = false;
				node.timeline.gotoAndPlay( "waterDrain" );
				setupStateOnLabel( node, "endWaterDrain", beaver.DEFEATED );
			}

			switch( beaver.state )
			{
				case beaver.BUSY:

					if( beaver.subState == beaver.TO )
					{
						this.setMotionToTarget( node, beaver.pointA );
						motion.velocity.x *= .5;
						beaver.subState = beaver.SWIM_TO;
						if ( spatial.scaleX < 0 )
						{
							spatial.scaleX *= -1;
						}
					}
					else if( beaver.subState == beaver.SWIM_TO )
					{
						targetDistance = GeomUtils.spatialDistance( spatial, beaver.pointA );
						
						if( targetDistance < TARGET_DELTA )
						{
							beaver.subState = beaver.FRO;
						}
					}
					else if( beaver.subState == beaver.FRO )
					{
						this.setMotionToTarget( node, beaver.pointB );
						motion.velocity.x *= .5;
						beaver.subState = beaver.SWIM_FRO;
						if ( spatial.scaleX > 0 )
						{
							spatial.scaleX *= -1;
						}
					}
					else if( beaver.subState == beaver.SWIM_FRO )
					{
						targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.pointB );
						
						if( targetDistance < TARGET_DELTA )
						{
							beaver.subState = beaver.TO;
						}
					}

					break;
				
				case beaver.IDLE:
					
					// choose an avaialble leak
					if( damControl.activeLeaks > 0 && !beaver.isBusy )	
					{
						var open:Vector.<LeakNode> = new Vector.<LeakNode>();
						var leakNode:LeakNode
						var leak:LeakComponent;
						for( leakNode = _leakList.head; leakNode; leakNode = leakNode.next )
						{
							leak = leakNode.leak;
							if ( leak.state == leak.ON && !leak.tended )
							{
								open.push( leakNode );
							}
						}
						
						if( open.length > 0 )
						{
							number = Math.round( Math.random() * ( open.length - 1 ));
							leakNode = open[ number ];
							leak = leakNode.leak;
							
							leak.tended = true;
							beaver.holeTarget = new Spatial( leakNode.spatial.x + 70, leakNode.spatial.y + 40 );
							beaver.state = beaver.SWIM_TO_ENTRANCE;
							beaver.leak = leak;
							beaver.isBusy = true;
							
							this.faceTarget( node, beaver.exitTarget );								
							this.setMotionToTarget( node, beaver.exitTarget, true );
						}
					}	
					break;
				
				// beaver approaches den exit
				case beaver.SWIM_TO_ENTRANCE:
					
					if( !beaver.isMoving )
					{
						this.setMotionToTarget( node, beaver.exitTarget, true );
					}
					else
					{
						targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.exitTarget );
						if( targetDistance < TARGET_DELTA )
						{
							beaver.isMoving = false;
							beaver.state = beaver.SWIM_TO_HOLE;
						}
					}
					break;
				
				// beaver approaches hole
				case beaver.SWIM_TO_HOLE:
					
					if( !beaver.isMoving )
					{
						this.setMotionToTarget( node, beaver.holeTarget );
					}
					else
					{
						targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.holeTarget );
						
						if( targetDistance < TARGET_DELTA )
						{
							node.motion.zeroMotion();
							beaver.isMoving = false;
							node.timeline.gotoAndPlay( "turnStart" );	// turn animation is followed by repair animation
							setupStateOnLabel( node, "turnEnd", node.beaver.REPAIR ); 
							//node.timeline.handleLabel( "repair", Command.create( node.audio.playCurrentAction, "repair" ) );
	
							beaver.state = beaver.TURN;
							beaver.leak.state = beaver.leak.REPAIR;
						}
					}
					break;

				// beaver repair hole until hurt or hole is repaired
				case beaver.REPAIR:

					// check for collision with log
					for( var logNode:TreeLogNode = _logList.head; logNode; logNode = logNode.next )
					{
						if( logNode.entityList.entities.length > 0 && logNode.motion.velocity.y > 15 )
						{
							if( node.display.displayObject.hitTestObject( logNode.log.hit ) )
							{
								node.motion.zeroMotion();
								node.tween.to( node.spatial, 1, { x : node.spatial.x + ( Math.random() * 30 ) - 60, y : node.spatial.y + 35 });
								
								beaver.state = beaver.HURT;
								beaver.leak.state = beaver.leak.ON;
								
								node.audio.playCurrentAction( HIT );
								node.timeline.gotoAndPlay( "bonked" );	// once aniamtion reaches "recoverComplete" set stunned to false
								setupStateOnLabel( node, "recoverComplete", beaver.SWIM_TO_DEN, "swim" );

								return;
							}
						}
					}
					// check to see if leak has been fully repaired
					if( beaver.leak.state == beaver.leak.OFF )
					{
						beaver.state = beaver.TURN;
						node.timeline.reverse = true;
						node.timeline.gotoAndPlay( "turnEnd" );
						setupStateOnLabel( node, "turnStart", node.beaver.SWIM_TO_DEN, "swim" ); 
					}
					break;
				
				// swimming to den
				case beaver.SWIM_TO_DEN:
					
					if( !node.beaver.isMoving )
					{
						faceTarget( node, beaver.exitTarget );	
						setMotionToTarget( node, beaver.exitTarget, true );
					}
					else
					{
						targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.exitTarget );
						if( targetDistance < 100 )	// previous range was 105, not sure why it was so much larger than other ranges? - bard
						{
							beaver.isMoving = false;
							beaver.state = beaver.SURFACING;
						}
					}
					
					break;
				
				case beaver.SURFACING:
					
					if( !node.beaver.isMoving )
					{
						this.setMotionToTarget( node, beaver.originTarget );
					}
					else
					{
						targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.originTarget );
						if( targetDistance < TARGET_DELTA )
						{
							beaver.isMoving = false;
							node.motion.zeroMotion();
							
							beaver.state = beaver.IDLE;
							node.spatial.rotation = 0;
							
							beaver.leak.tended = false;
							beaver.isBusy = false;
							beaver.state = beaver.IDLE;
						}
					}
					break;
				
				case beaver.GRUMPY:
					
					if( spatial.y < beaver.SWIM_Y )
					{
						spatial.y += 5;
					}
					else
					{
						spatial.y = beaver.SWIM_Y;
						motion.velocity.y = 0;
					}
					
					break;
				
				case beaver.DEFEATED:
					
					if( !beaver.isMoving )
					{
						node.timeline.gotoAndPlay( "running" );
						faceTarget( node, beaver.exitTarget );
						motion.velocity = new Point( 150, 0 );
						beaver.isMoving = true;
						beaver.timer = 0;
					}
					else
					{
						
						beaver.timer += time;
						if( beaver.timer > 3 )
						{
							if( !_dispatched )
							{
								_dispatched = true;
								victory.dispatch();
							}
							
							targetDistance = GeomUtils.spatialDistance( node.spatial, beaver.exitTarget );
							if( targetDistance < 100 )
							{
								beaver.state = beaver.OFF;
								node.sleep.sleeping = true;
							}							
						}
					}
					
					break;
			}
		}
		
		/**
		 * Method to set Hook state on label reached. 
		 * @param node
		 * @param label
		 * @param state
		 * @param nextLabel
		 */
		private function setupStateOnLabel( node:BeaverNode, label:String, state:String, nextLabel:String = "" ):void
		{
			node.timeline.handleLabel( label, Command.create( changeStateOnLabel, node, state, nextLabel ) );
		}
		
		/**
		 *  Handler for setupStateOnLabel.
		 * @param node
		 * @param state
		 * @param nextLabel
		 */
		private function changeStateOnLabel( node:BeaverNode, state:String, nextLabel:String = "" ):void
		{
			node.beaver.state = state;
			if( nextLabel != "" )
			{
				node.timeline.reverse = false;
				node.timeline.gotoAndPlay( nextLabel );
			}
		}
		
		private function setMotionToTarget( node:BeaverNode, target:Spatial, rotateToTarget:Boolean = false ):void
		{	
			var angle:Number;
			var beaver:BeaverComponent = node.beaver;
			var degrees:Number;
			var delta:Number;
			var dx:Number;
			var dy:Number;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			var targetDistance:Number;
			
			dx = target.x - spatial.x;
			dy = target.y - spatial.y;
			angle = Math.atan2( dy, dx );
			
			motion.velocity.x = Math.cos( angle ) * beaver.MOVE_VELOCITY;
			motion.velocity.y = Math.sin( angle ) * beaver.MOVE_VELOCITY;
			
			node.beaver.isMoving = true;
			
			spatial.rotation = 0;
			
			if( rotateToTarget )
			{
				degrees = angle * (180 / Math.PI);
				delta = spatial.rotation - degrees;
				
				if ( delta < -180 )
				{
					spatial.rotation = spatial.rotation + 360;
					delta += 360;
				}
				else if ( delta >= 180 )
				{
					spatial.rotation = spatial.rotation - 360;
					delta -= 360;
				}
				
				if ( Math.abs( delta ) < .2 )
				{
					spatial.rotation = degrees;
				}
				else
				{
					spatial.rotation = spatial.rotation - delta * .1;
				}
			}
		}
		
		/**
		 * Adjusts x scale so entity is facing target.
		 * @param node
		 * @param target
		 */
		private function faceTarget( node:BeaverNode, target:Spatial ):void
		{
			var beaver:BeaverComponent = node.beaver;
			var spatial:Spatial = node.spatial;
			
			if (( spatial.scaleX > 0 ) && ( spatial.x < target.x )) 
			{
				spatial.scaleX *= -1;
				spatial.x -= 65;
			}
			else if (( spatial.scaleX < 0 ) && ( spatial.x > target.x ))
			{
				spatial.scaleX *= -1;
				spatial.x += 65;
			}
		}
	}
}