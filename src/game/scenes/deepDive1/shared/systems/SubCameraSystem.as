package game.scenes.deepDive1.shared.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.components.motion.RotateControl;
	import game.components.scene.SceneInteraction;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.nodes.FilmableNode;
	import game.scenes.deepDive1.shared.nodes.SubCameraNode;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class SubCameraSystem extends System
	{
		private const LIGHT_DURATION:Number = 3;	// duration lights stay on in seconds
		
		private var _filmableNodes:NodeList;
		private var _subCameraNode:SubCameraNode;
		private var _activeFilmable:FilmableNode;
		private var _currentCount:Number = 0;
		private var _step:Number = 0;
		private var _timePerStep:Number;
		private var _flashTime:Number = 0;
		private var _flashCount:Number = 0;
		private var _lightDuration:Number = 0;
		
		/**
		 * System to handle when the player is capturing a fish with the camera
		 */
		public function SubCameraSystem()
		{		
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_subCameraNode = systemManager.getNodeList(SubCameraNode).head;
			_filmableNodes = systemManager.getNodeList(FilmableNode);
			super.addToEngine(systemManager);
		}
		
		override public function update(time:Number):void
		{
			if( _subCameraNode == null )
			{
				_subCameraNode = super.systemManager.getNodeList(SubCameraNode).head;
			}

			if( _activeFilmable != null )	// if actively filming, update status
			{
				updateActive(time);
			}
			else if(_subCameraNode != null)
			{
				var subCamera:SubCamera = _subCameraNode.subCamera;
				if(subCamera.flashColor != null)
				{
					_flashTime += time;
					
					if(_flashCount == subCamera.numberOfFlashes)
					{
						subCamera.flashColor = null;
						return;
					}
					
					var color:uint;
					var colorString:String = subCamera.flashColor;
					if(subCamera.flashColor == SubCamera.RED)	
						color = SubCamera.COLOR_RED;
					else if(subCamera.flashColor == SubCamera.GREEN)
						color = SubCamera.COLOR_GREEN;
					
					if(_flashTime >= .25)
					{
						_flashCount++;
						
						if(_flashCount % 2 == 0)
						{
							color = subCamera.originalColor;
							colorString = SubCamera.ORIGINAL;
						}
						_flashTime = 0;
						subCamera.changeAllLightColors(color);
						subCamera.changeTopLight(colorString);
					}
					return;
				}
				// update filmingCounter
				var filmable:Filmable;
				for(var node:FilmableNode = _filmableNodes.head; node; node = node.next)
				{
					filmable = node.filmable;
					if( filmable.attemptFilm )					// if trying to film
					{
						var sceneInteraction:SceneInteraction = node.sceneInteraction;
						//check range
						var targetSpatial:Spatial = node.spatial;
						if( !checkInRange( targetSpatial ) )	// if not within range of filmable
						{
							_lightDuration = LIGHT_DURATION;
							subCamera.changeAllLightColors(SubCamera.COLOR_YELLOW);
							subCamera.topLight.get(Timeline).gotoAndStop(SubCamera.ORIGINAL);
							sceneInteraction.approach = true;
							sceneInteraction.activated = true;
							sceneInteraction.reached.addOnce( filmable.onPress ); // TODO :: remove on interrupt?
							filmable.state = filmable.FILMING_OUT_OF_RANGE;
						}
						else									// if within range of filmable
						{
							// reset SceneInteraction
							sceneInteraction.approach = false;
							sceneInteraction.activated = false;
							sceneInteraction.reached.remove( filmable.onPress );
							
							// make sure player is facing target
							forceFace( node.spatial );
							
							// check filmable
							if( !filmable.isFilmable )
							{
								_lightDuration = LIGHT_DURATION;
								subCamera.changeAllLightColors(SubCamera.COLOR_RED);
								subCamera.changeTopLight(SubCamera.RED);
								filmable.state = filmable.FILMING_BLOCK;
							}
							else if( filmable.captured )
							{
								_lightDuration = LIGHT_DURATION;
								subCamera.changeAllLightColors(SubCamera.COLOR_YELLOW);
								subCamera.changeTopLight(SubCamera.ORIGINAL);
								filmable.state = filmable.FILMING_COMPLETE;
							}
							else
							{
								// turn on lights, camera
								subCamera.topLight.get(Timeline).gotoAndStop(SubCamera.GREEN);
								subCamera.changeBack();
								subCamera.iris.get(Timeline).gotoAndPlay("open");
								EntityUtils.visible(subCamera.lightBeamR, true );
								EntityUtils.visible(subCamera.lightBeamL, true );
								
								// add components to make lights rotate towards target
								var rotateControl:RotateControl = new RotateControl();
								rotateControl.origin = _subCameraNode.spatial;
								rotateControl.fromTargetToOrigin = false;
								rotateControl.targetInLocal = false;
								var target:TargetSpatial = new TargetSpatial(targetSpatial);
								subCamera.lightBeamR.add( rotateControl );
								subCamera.lightBeamR.add( target);
								subCamera.lightBeamL.add( rotateControl);
								subCamera.lightBeamL.add( target );

								filmable.activated = true;
								_activeFilmable = node;
								
								// setup time step
								_timePerStep = node.filmable.cameraTime / subCamera.lights.length;
								_currentCount = 0;
								_step = 0;
								filmable.state = filmable.FILMING_START;
							}
						}
						
						filmable.attemptFilm = false;
						filmable.stateSignal.dispatch( node.entity );
					}
				}
				
				_lightDuration -= time;
				if(_lightDuration <= 0)
				{
					subCamera.changeAllLightColors(subCamera.originalColor);
					subCamera.changeTopLight(SubCamera.ORIGINAL);
				}
			}
		}
		
		/**
		 * Updating filming, once complete dispatches signal. 
		 * @param time
		 * 
		 */
		private function updateActive(time:Number):void
		{
			var filmable:Filmable = _activeFilmable.filmable;
			
			if( filmable.isFilmable)
			{
				if( checkFacing( _subCameraNode.spatial ) )
				{
					if(checkInRange(_activeFilmable.spatial))
					{
						// update & check timer hud
						_currentCount += time;
						if( _currentCount >= _timePerStep )
						{
							_step++;
							if( _step > _subCameraNode.subCamera.lights.length)
							{
								filmable.captured = true;
								filmable.state = filmable.FILMING_COMPLETE;
								filmable.stateSignal.dispatch( _activeFilmable.entity );
								resetActive();
							}
							else
							{
								_currentCount = 0;
								var reverse:Boolean = _subCameraNode.spatial.scaleX < 0;
								_subCameraNode.subCamera.changeLight(_step - 1, SubCamera.COLOR_GREEN, reverse);
							}
						}
						return;
					}
				}
			}
			
			filmable.state = filmable.FILMING_STOP;
			filmable.stateSignal.dispatch( _activeFilmable.entity );
			resetActive();
		}
		
		public function resetActive():void
		{
			// deactivate filmable
			_activeFilmable.filmable.activated = false;
			_activeFilmable = null;
			
			// reset timer hud
			//Timeline(_subCameraNode.subCamera.hud.get(Timeline)).reset(false);
			//_subCameraNode.subCamera.hud.get(Display).visible = false;
			_currentCount = 0;
			_step = 0;
			var subCamera:SubCamera = _subCameraNode.subCamera;
			subCamera.changeAllLightColors(_subCameraNode.subCamera.originalColor);
			subCamera.iris.get(Timeline).gotoAndPlay("close");
			subCamera.topLight.get(Timeline).gotoAndStop(SubCamera.ORIGINAL);
			
			subCamera.lightBeamR.remove( RotateControl );
			subCamera.lightBeamR.remove( TargetSpatial );
			subCamera.lightBeamL.remove( RotateControl );
			subCamera.lightBeamL.remove( TargetSpatial );
			EntityUtils.visible( subCamera.lightBeamR, false );
			EntityUtils.visible( subCamera.lightBeamL, false );
		}
		
		public function checkFacing( targetSpatial:Spatial ):Boolean
		{
			var cameraSpatial:Spatial = _subCameraNode.spatial;

			// check camera is facing target
			if( cameraSpatial.scaleX > 0 )
			{
				if( targetSpatial.x > cameraSpatial.x )
				{
					return false;
				}
			}
			else
			{
				if( cameraSpatial.x > targetSpatial.x )
				{
					return false;
				}
			}
			return true;
		}
		
		public function forceFace( targetSpatial:Spatial  ):void
		{
			// TODO :: this needs work, may need to apply a slight velocity
			if( !checkFacing( targetSpatial ) )
			{
				_subCameraNode.spatial.scaleX *= -1;
			}
		}
		
		/**
		 * Determine is filmable entity is within range of camera.
		 * @param cameraNode
		 * @param fishNode
		 * @return 
		 * 
		 */
		public function checkInRange( targetSpatial:Spatial ):Boolean
		{
			//determine if sub is facing target
			var cameraSpatial:Spatial = _subCameraNode.spatial;
			
			// check the camera distance & angle from target
			var distance:Number = GeomUtils.dist( targetSpatial.x, targetSpatial.y, cameraSpatial.x, cameraSpatial.y );
			if( distance > _subCameraNode.subCamera.distanceMin + targetSpatial.width/2 &&  distance < _subCameraNode.subCamera.distanceMax )
			{
				// make sure player is facing target
				forceFace( targetSpatial );
				var facingLeft:Boolean = cameraSpatial.scaleX > 0;
				
				// check degrees
				var degrees:Number = Math.abs(GeomUtils.degreesBetween( targetSpatial.x, targetSpatial.y, cameraSpatial.x, cameraSpatial.y ));
				if( facingLeft )
				{
					return ( 180 - degrees < _subCameraNode.subCamera.angle )
				}
				else
				{
					return ( degrees < _subCameraNode.subCamera.angle );
				}
			}
			
			return false;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			_filmableNodes = null;
			_activeFilmable = null;
			_subCameraNode = null;
			systemManager.releaseNodeList(Filmable);
			systemManager.releaseNodeList(SubCameraNode);
			super.removeFromEngine(systemManager);
		}
	}
}