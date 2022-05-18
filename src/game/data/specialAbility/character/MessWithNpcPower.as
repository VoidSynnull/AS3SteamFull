package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.creators.InteractionCreator;
	
	import game.components.input.Input;
	import game.creators.ui.ToolTipCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.ui.card.CharacterContentView;
	import game.util.DisplayAlignment;
	
	public class MessWithNpcPower extends SpecialAbility
	{
		private var selectCharacter:MovieClip;
		public var _messWithSelf:Boolean = false;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if(group is CharacterContentView)
				return;
			
			if(!this.data.isActive)
			{
				this.data.isActive = true;
				
				this.shellApi.loadFile(this.shellApi.assetPrefix + "ui/elements/select_character.swf", selectCharacterLoaded);
				
				var nodeList:NodeList = systemManager.getNodeList(NpcNode);
				var interaction:Interaction;
				for(var npc:NpcNode = nodeList.head; npc; npc = npc.next)
				{
					interaction = npc.entity.get(Interaction);
					if(interaction == null || interaction.lock)
						continue;
					interaction.click.addOnce(messWithNpc);
				}
				
				if(_messWithSelf)
				{
					interaction = InteractionCreator.addToEntity(shellApi.player, ["click"]);
					interaction.click.addOnce(messWithNpc);
					ToolTipCreator.addToEntity(shellApi.player);
				}
				
				var input:Input = shellApi.inputEntity.get(Input);
				input.inputDown.addOnce(inputDown);
			}
		}
		
		private function selectCharacterLoaded(clip:MovieClip):void
		{
			if(this.data.isActive)
			{
				if(clip)
				{
					selectCharacter = clip;
					this.shellApi.currentScene.overlayContainer.addChildAt(clip, 0);
					DisplayAlignment.alignToArea(clip, new Rectangle(0, 10, this.shellApi.viewportWidth, this.shellApi.viewportHeight), null, DisplayAlignment.MID_X_MIN_Y);
				}
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(this.data.isActive)
			{
				var motion:Motion = node.entity.get(Motion);
				if(motion)
				{
					if(motion.velocity.length > 20)
					{
						this.data.isActive = false;
						//this.data.remove();
					}
				}
			}
		}
		
		protected function inputDown(input:Input):void
		{
			trace("clicked nothing");
			stopMessingAround();
		}
		
		protected function messWithNpc(npc:Entity):void
		{
			trace("clicked npc");
			stopMessingAround();
		}
		
		protected function stopMessingAround():void
		{
			this.data.isActive = false;
			
			if(selectCharacter)
			{
				if(selectCharacter.parent)
				{
					selectCharacter.parent.removeChild(selectCharacter);
				}
				selectCharacter = null;
			}
			
			var nodeList:NodeList = systemManager.getNodeList(NpcNode);
			var interaction:Interaction;
			for(var npc:NpcNode = nodeList.head; npc; npc = npc.next)
			{
				interaction = npc.entity.get(Interaction);
				if(interaction != null)
					interaction.click.remove(messWithNpc);
			}
			
			if(_messWithSelf)
			{
				interaction = shellApi.player.get(Interaction);
				interaction.click.remove(messWithNpc);
				ToolTipCreator.removeFromEntity(shellApi.player);
			}
			
			var input:Input = shellApi.inputEntity.get(Input);
			input.inputDown.remove(inputDown);
		}
	}
}