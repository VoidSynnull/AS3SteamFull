package game.systems.ui
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Linear;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.nodes.entity.character.PlayerNode;
	import game.nodes.ui.ToolTipNode;
	import game.ui.toolTips.ToolTipView;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class ToolTipSystem extends System
	{
		
		override public function addToEngine( systemManager : Engine ) : void
		{
			_nodes = systemManager.getNodeList( ToolTipNode );
			_playerNodes = systemManager.getNodeList( PlayerNode );
		}
		
		override public function update( time : Number ) : void
		{
			// wait prevents tooltips from showing up right away when enetering a scene
			if(_wait == 0)
			{
				_wait = _waitTime;
				
				var playerNode:PlayerNode = _playerNodes.head;
				
				if ( playerNode )
				{
					var pSpatial:Spatial = playerNode.spatial;		
					var dist:Number;				
					var node:ToolTipNode;
					
					for ( node = _nodes.head; node; node = node.next )
					{				
						if (EntityUtils.sleeping(node.entity))
						{
							if(node.display.displayObject != null)
							{
								if(node.tween.tweening)
								{
									node.tween.killAll();
								}
								
								node.display.alpha = 0;
								node.display.displayObject.alpha = 0;
								node.toolTip.showing = false;
							}
							continue;
						}
						
						if(node.display.displayObject == null)
						{
							if(!node.toolTip.loadingAsset)
							{
								ToolTipView(super.group).loadToolTipAsset(node.entity);
							}
							continue;
						}
						else if(!node.toolTip.showing)
						{
							dist = GeomUtils.distSquared(pSpatial.x, pSpatial.y, node.spatial.x, node.spatial.y);
						
							if(dist < VISIBILITY_RANGE && dist > MINIMUM_RANGE)
							{
								node.toolTip.showing = true;
								node.tween.to(node.display, .2, { alpha : 1, ease:Linear.easeNone });
								node.tween.to(node.display, .2, { delay : 2.5, alpha : 0, ease:Linear.easeNone });
							}
							else
							{
								node.toolTip.showing = false;
								node.tween.to(node.display, .2, { alpha : 0, ease:Linear.easeNone });
							}
						}
					}
				}
			}
			else
			{
				_wait--;
			}
		}

		override public function removeFromEngine( systemManager : Engine ) : void
		{
			systemManager.releaseNodeList( ToolTipNode );
			systemManager.releaseNodeList( PlayerNode );
			_nodes = null;
			_playerNodes = null;
		}
		
		private var _nodes:NodeList;
		private var _playerNodes:NodeList;
		private var _wait:Number = 0;
		private var _waitTime:Number = 10;
		private static const VISIBILITY_RANGE:uint = 120000;
		private static const MINIMUM_RANGE:uint = 10000;
	}
}
