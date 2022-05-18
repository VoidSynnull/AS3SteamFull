package game.systems.input
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Interaction;
	
	import game.components.input.Input;
	import game.nodes.input.InputNode;
	import game.nodes.input.InteractionNode;
	import game.util.EntityUtils;

	public class InteractionSystem extends System
	{
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(InteractionNode);
			_nodes.nodeRemoved.add( nodeRemoved );
			
			var inputNodes:NodeList = systemManager.getNodeList(InputNode);
			var inputNode:InputNode = inputNodes.head;
			
			_input = inputNode.input;
		}
		
		override public function update(time:Number):void
		{
			var node:InteractionNode;
			var interaction:Interaction;

			for (node = _nodes.head; node; node = node.next)
			{
				if (EntityUtils.sleeping(node.entity))
				{
					continue;
				}
				
				interaction = node.interaction;
				
				if(!interaction._manualLock)
				{
					interaction._lock = _input.lockInput;
				}
				
				if(_input.lockInput)
				{
					continue;
				}
				
				/*
				Drew - There have been bugs with lingering UI rollovers caused by Events
				happening, but then we wait for the system to "process" the Events before
				we dispatch(). This causes inconsistencies with the order of what's already happened.
				
				It's not the "perfect" way to do it, but to remove this issue
				we can dispatch() right from the Interaction Component as soon as we get our
				Event.
				*/
				
				if (interaction.invalidate )
				{
					interaction.invalidate = false;
					
					/*if (interaction._isClicked || interaction.isClicked) 
					{  
						interaction.isClicked = interaction._isClicked;
						if(interaction._isClicked)
						{
							interaction.click.dispatch(node.entity);
							interaction._isClicked = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.clickedEvent = null;
						}
					}
					if (interaction._isOut || interaction.isOut) 
					{ 
						interaction.isOut = interaction._isOut;
						if(interaction._isOut)
						{
							interaction.out.dispatch(node.entity);
							interaction._isOut = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.outEvent = null;
						}
					}
					if (interaction._isUp || interaction.isUp) 
					{ 
						interaction.isUp = interaction._isUp;
						if(interaction._isUp)
						{
							interaction.up.dispatch(node.entity); 
							interaction._isUp = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.upEvent = null;
						}
					}
					if (interaction._isDown || interaction.isDown) 
					{ 
						interaction.isDown = interaction._isDown;
						if(interaction._isDown)
						{
							interaction.down.dispatch(node.entity);
							interaction._isDown = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.downEvent = null;
						}
					}
					
					if (interaction._isOver || interaction.isOver) 
					{ 
						interaction.isOver = interaction._isOver;
						if(interaction._isOver)
						{
							interaction.over.dispatch(node.entity);
							interaction._isOver = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.overEvent = null;
						}
					}
					if (interaction._isReleasedOutside || interaction.isReleasedOutside) 
					{ 
						interaction.isReleasedOutside = interaction._isReleasedOutside;
						if(interaction._isReleasedOutside)
						{
							interaction.releaseOutside.dispatch(node.entity); 
							interaction._isReleasedOutside = false;
							interaction.invalidate = true;
						}
						else
						{
							interaction.releasedOutsideEvent = null;
						}
					}*/
					if (interaction._keyIsDown || interaction.keyIsDown) 
					{  
						interaction.keyIsDown = interaction._keyIsDown;
						if(interaction._keyIsDown)
						{
							interaction.keyDown.dispatch(node.entity);
							interaction._keyIsDown = 0;
							interaction.invalidate = true;
						}
						else
						{
							interaction.keyDownEvent = null;
						}
					}
					if (interaction._keyIsUp || interaction.keyIsUp) 
					{ 
						interaction.keyIsUp = interaction._keyIsUp;
						if(interaction._keyIsUp)
						{
							interaction.keyUp.dispatch(node.entity);
							interaction._keyIsUp = 0;
							interaction.invalidate = true;
						}
						else
						{
							interaction.keyUpEvent = null;
						}
					}
				}
			}
		}
					
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(InputNode);
			systemManager.releaseNodeList(InteractionNode);
			_nodes = null;
			_input = null;
		}
				
		private function nodeRemoved(node:InteractionNode):void
		{
			node.interaction.removeAll();
		}
		
		private var _nodes:NodeList;
		private var _input:Input;
	}
}
