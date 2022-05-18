// Status: retired
// Usage (1) ads
// Used by avatar item limited_wcte_balloon

package game.data.specialAbility.character
{	
	import flash.media.Sound;
	import flash.net.URLRequest;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class ButtKite extends SpecialAbility
	{		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
						
			// create balloon data
			var id:String = "AddBalloon";
			var className:String = "game.data.specialAbility.character.AddBalloon";
			var balloonClass:Class = ClassUtils.getClassByName(className);
			balloonData = new SpecialAbilityData(balloonClass);
			balloonData.id = id;
			balloonData.triggerable = false;
			// copy params
			balloonData.params = this.data.params.duplicate();
			
			// check existing abilities
			var foundBalloon:Boolean = false;
			var abilities:Array = shellApi.profileManager.active.specialAbilities;
			for(var i:Number = 0 ; i < abilities.length; i++)
			{
				// check if butt kite ability has already been added
				if(abilities[i].@id == id)
				{
					foundBalloon = true;
					break;
				}
			}
			
			// if missing corresponding item part, then remove
			if (!SkinUtils.hasSkinValue(shellApi.player, SkinUtils.ITEM, "limited_wcte_balloon"))
			{
				trace("buttkite remove because no item");
				CharUtils.removeSpecialAbility(shellApi.player, balloonData);
				CharUtils.removeSpecialAbility(shellApi.player, this.data);
			}
			// if no balloon, then add balloon ability
			else if (!foundBalloon)
			{
				trace("buttkite add");
				CharUtils.addSpecialAbility(node.entity, balloonData, true);
			}
		}
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if not already active
			if (!this.data.isActive)
			{
				
				// get balloon entity
				var balloon:Entity = super.group.getEntityById("balloon");
				if (balloon)
				{
					// get balloon timeline
					var timeline:Timeline = balloon.get(Timeline);
					if (timeline)
					{
						this.data.isActive = true;
						// play animation to end
						balloon.get(Timeline).gotoAndPlay(2);
						TimelineUtils.onLabel( balloon, "end", Command.create(deactivate, node));
						// play sounds inside balloon clip
						while (true)
						{
							var num:int = Math.floor(_numSounds * Math.random()) + 1;
							if (num != lastSound)
							{
								lastSound = num;
								var fartSound:Sound = new Sound(new URLRequest(super.shellApi.assetPrefix + this.data.getInitParam("soundPath") + num + ".mp3"));
								fartSound.play();
								break;
							}
						}
					}
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			this.data.isActive = false;
		}
		
		override public function removeSpecial(node:SpecialAbilityNode):void
		{
			trace("buttkite remove normal");
			super.removeSpecial(node);
			super.shellApi.specialAbilityManager.removeSpecialAbility(node.entity, balloonData.id);
		}
		
		public var _numSounds:Number = 0;
		
		private var lastSound:int = 0;
		private var balloonData:SpecialAbilityData;
	}
}