package game.systems.ui
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	
	import game.components.animation.FSMControl;
	import game.data.animation.entity.character.Fall;
	import game.nodes.entity.character.PlayerNode;
	import game.nodes.ui.NavigationArrowNode;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.util.PlatformUtils;
	
	// wrb - still need to tie these into the character motion to get the true screen offsets for movement, jump and duck heights.
	public class NavigationArrowSystem extends ListIteratingSystem
	{
		public function NavigationArrowSystem()
		{
			super(NavigationArrowNode, updateNode);
			super._defaultPriority = SystemPriorities.loadAnim;
		}
		
		private function updateNode(node:NavigationArrowNode, time:Number):void
		{
			// get arrow display
			var vDisplay:MovieClip = MovieClip(node.display.displayObject);
			var playerNode:PlayerNode = _playerNodeList.head;
			
			if (vDisplay != null && playerNode != null)
			{
				var fade:Boolean = PlatformUtils.isMobileOS;
				/*if(!fade && playerNode.characterMotionControl != null)
				{
					fade = !playerNode.characterMotionControl.allowAutoTarget && playerNode.characterMotionControl.targetJumping;
				}*/
				
				if(fade)
				{
					if(playerNode.motionControl.moveToTarget && playerNode.motionControl.inputActive && !playerNode.motionControl.lockInput && ( !playerNode.characterMotionControl || !playerNode.characterMotionControl.waitingForRelease))
					{
						if(node.display.alpha < 1)
						{
							node.display.alpha += .2;
						}
						else
						{
							node.display.alpha = 1;
						}
					}
					else
					{
						if(node.display.alpha > 0)
						{
							node.display.alpha -= .2;
						}
						else
						{
							node.display.alpha = 0;
						}
						return;
					}
				}
				else if(node.display.alpha == 0)
				{
					node.cursor._invalidate = true;
				}
				
				// delta offsets from center of avatar with vertical offset
				var deltaX:Number = node.spatial.x - _shellApi.sceneToGlobal(playerNode.spatial.x, "x");
				var deltaY:Number = node.spatial.y - _shellApi.sceneToGlobal(playerNode.spatial.y, "y");
				if(isNaN(_offset))
				{
					_offset = 85 * _shellApi.camera.scale;
				}
				
				// get angle and distance from deltas 		
				var angle:Number = Math.atan(deltaY / deltaX) * 180 / Math.PI;
				var vScale:Number = Math.sqrt(deltaX * deltaX + deltaY * deltaY) / 100;

				if (deltaX >= 0)
					angle += 180;
				
				// if y distance is near feet then show down cursor
				if (deltaY > _offset && Math.abs(deltaX) < _offset)
				{
					node.timeline.gotoAndStop("down");
					node.spatial.rotation = angle;
				}
				// if y distance above head then show up cursor
				else if (deltaY < -_offset)
				{
					node.timeline.gotoAndStop("up");
					node.spatial.rotation = angle;
				}
				// is close to avatar center then show none cursor
				else if (Math.abs(deltaX) < _offset * .25)
				{
					node.timeline.gotoAndStop("none");
					node.spatial.rotation = angle;
				}
				else
				{
					node.timeline.gotoAndStop("side");
					if (deltaX >= 0)
						node.spatial.rotation = 180;
					else
						node.spatial.rotation = 0;
				}
				
				// if base is found then scale it
				if (vDisplay.base != null)
				{
					if (vScale > 7)
						vScale = 7;
					vDisplay.base.scaleX = vScale; 
				}
				
				if(node.input.offscreen)
				{
					node.display.visible = false;
				}
				else if(!node.display.visible)
				{
					node.display.visible = true;
					node.spatial.x = node.input.target.x;
					node.spatial.y = node.input.target.y;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_playerNodeList = systemManager.getNodeList(PlayerNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(NavigationArrowNode);
			systemManager.releaseNodeList(PlayerNode);
			
			_playerNodeList = null;
			
			super.removeFromEngine(systemManager);
		}
		
		private var _playerNodeList:NodeList;
		private var _offset:Number;
		
		[Inject]
		public var _shellApi:ShellApi
	}
	
	/*
	if(PlatformUtils.isMobileOS)
	{
	var show:Boolean = true;
	
	if(node.input.inputActive && node.navigationArrow.waitTime > 0)
	{
	node.navigationArrow.waitTime -= time;
	show = false;
	}
	
	if(!node.input.inputActive || node.input.lockInput)
	{
	node.navigationArrow.waitTime = CharacterState.CLICK_DELAY;
	show = false;
	}
	
	if(!show)
	{
	if(node.display.alpha > 0)
	{
	node.display.alpha -= .2;
	}
	else
	{
	node.display.alpha = 0;
	}
	
	return;
	}
	else
	{
	if(node.display.alpha < 1)
	{
	node.display.alpha += .2;
	}
	else
	{
	node.display.alpha = 1;
	}
	}
	}
	*/
	
}