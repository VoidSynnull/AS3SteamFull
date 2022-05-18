package game.systems.entity.character
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Id;
	import game.components.entity.Dialog;
	import game.nodes.entity.character.DialogInteractionNode;
	import game.systems.entity.character.states.CharacterState;
	
	import org.osflash.signals.Signal;
	
	public class DialogInteractionSystem extends System
	{
		public function DialogInteractionSystem()
		{
			
		}
		/*
		override public function update(time:Number):void
		{
			var node:CharacterInteractionNode;
			
			for (node = _nodes.head; node; node = node.next)
			{
				if(node.hit.open)
				{
					node.hit.open = false;
					openDoor(node.entity);
					return;
				}
			}
		}
		*/
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(DialogInteractionNode);
			_nodes.nodeAdded.add(nodeAdded);
			var node:DialogInteractionNode;
			
			for(node = _nodes.head; node; node = node.next)
			{
				nodeAdded(node);
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(DialogInteractionNode);
			_nodes = null;
		}
		
		private function nodeAdded(node:DialogInteractionNode):void
		{
			if(node.sceneInteraction.reached == null)
			{
				node.sceneInteraction.reached = new Signal(Entity);
			}
			
			// require specific states to trigger dialog
			if( node.sceneInteraction.validCharStates == null ) 	
			{ 
				node.sceneInteraction.validCharStates = _validStates.slice(); 
			}
			else
			{
				node.sceneInteraction.validCharStates.concat(_validStates);	// TODO :: should we check for duplicates, is it worth it? - Bard
			}
			node.sceneInteraction.reached.add(onEntityReached);
		}
		
		private function onEntityReached( approachingEntity:Entity, clickedEntity:Entity ):void
		{
			// skip npc friends
			if (clickedEntity.get(Id).id.substr(0,10) == "npc_friend")
				return;
			var dialog:Dialog = clickedEntity.get(Dialog);
			if(dialog != null)
			{
				dialog.sayCurrent();
			}
		}
				
		private var _nodes : NodeList;
		private var _validStates : Vector.<String> = new <String>[ CharacterState.STAND, CharacterState.WALK, CharacterState.SWIM ];
	}
}
