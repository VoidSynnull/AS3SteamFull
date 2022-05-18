package game.scenes.backlot.soundStage2
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookData;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.CharacterGroup;
	import game.systems.timeline.TimelineRigSystem;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	
	public class MakeUpStation extends Popup
	{
		private var lookParts:Vector.<SkinPart>;
		private var lipValues:Vector.<Array>;
		
		private var looks:Array = ["bl_promqueenc", "bl_punkc","bl_gothgirlc"];
		
		private var lips1:Array = [443,444,"medusa",445];
		private var lips2:Array = [19,446,447,448];
		private var lips3:Array = [449,450,451,"pCowgirl1"];
		
		private var look:int = 0;
		private var lip:int = 0;
		private var mark:int = 1;
		
		private var numInteractions:Array = [3,4,6];
		private var interactionNames:Array = ["look", "lipstick", "markColor"];
		private var interactionMethods:Vector.<Function>;
		
		private var backlot:BacklotEvents;
		private var content:MovieClip;
		private var player:Entity;
		private var playerLook:LookData;
		private var charGroup:CharacterGroup;
		
		public function MakeUpStation(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/soundStage2/";
			super.screenAsset = "makeupStation.swf";
			super.darkenBackground = true;
			darkenAlpha = .75;
			super.init(container);
			
			charGroup = super.getGroupById("characterGroup" ) as CharacterGroup;
			if( charGroup == null )
				charGroup = super.addChildGroup( new CharacterGroup() ) as CharacterGroup;
			
			removeSystemByClass( TimelineRigSystem );
			
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			super.layout.centerUI(content);
			
			setUp();
		}
		
		private function setUp():void
		{			
			lipValues = new Vector.<Array>();
			lipValues.push(lips1,lips2,lips3);
			
			interactionMethods = new Vector.<Function>();
			interactionMethods.push(changeLook, changeLipColor, changeMarkColor);
			
			playerLook = SkinUtils.getLook(this.shellApi.player, true);
			
			player = charGroup.createDummy( "player", playerLook, CharUtils.DIRECTION_LEFT, "", content, this, onCharLoaded);
			
			for(var i:int = 0; i < numInteractions.length; i ++)
			{
				setUpInteractions(i);
			}
			
			createResetInteraction();
			
			createButtons();
		}
		
		private function createButtons():void
		{
			var clip:MovieClip = content.cancelBtn;
			TextUtils.convertText( clip.base.tf, new TextFormat( "CreativeBlock BB" ), "Cancel"  );
			var button:Entity = ButtonCreator.createButtonEntity(clip, this, clickCancel);
			
			clip = content.acceptBtn;
			TextUtils.convertText( clip.base.tf, new TextFormat( "CreativeBlock BB" ), "Accept"  );
			ColorUtil.colorize( clip.base.color, 0x00E100 );
			button = ButtonCreator.createButtonEntity(clip, this, clickAccept);
		}
		
		private function clickAccept(button:Entity):void
		{
			SkinUtils.applyLook(shellApi.player, SkinUtils.getLook(player, false));
			super.close();
		}
		
		private function clickCancel(button:Entity):void
		{
			super.close();
		}
		
		private function createResetInteraction():void
		{
			var clip:MovieClip = content.makeupRemover;
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, content);
			Display(entity.get(Display)).alpha = 0;
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK],clip);
			interaction.click.add(removeMakeup);
			ToolTipCreator.addToEntity(entity);
		}
		
		private function removeMakeup(button:Entity):void
		{
			SkinUtils.emptySkinPart(player, lookParts[0].id);// for when the original mark part was null
			SkinUtils.setSkinPart(player, lookParts[0].id,playerLook.getValue(lookParts[0].id));// does not remove skin parts when they are null
			SkinUtils.setSkinPart(player, lookParts[1].id,playerLook.getValue(lookParts[1].id));// alwasy has a mouth so it works fine
		}
		
		private function setUpInteractions(interactionNumber:int):void
		{
			for(var i:int = 1; i <= numInteractions[interactionNumber]; i++)
			{
				var clip:MovieClip = content[interactionNames[interactionNumber]+i];
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip, content);
				Display(entity.get(Display)).alpha = 0;
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK],clip);
				interaction.click.add(Command.create(interactionMethods[interactionNumber], i - 1));
				ToolTipCreator.addToEntity(entity);
			}
		}
		
		private function changeLook(button:Entity, lookNumber:int):void
		{
			look = lookNumber;
			changeMarkColor(button, mark);
			changeLipColor(button, lip);
		}
		
		private function changeMarkColor(button:Entity, markColorNumber:int):void
		{
			mark = markColorNumber;
			SkinUtils.setSkinPart(player, lookParts[0].id,looks[look]+String(mark + 1));
		}
		
		private function changeLipColor(button:Entity, lipColorNumber:int):void
		{
			lip = lipColorNumber;
			SkinUtils.setSkinPart(player, lookParts[1].id,lipValues[look][lip]);
		}
		
		private function onCharLoaded(character:Entity):void
		{
			CharUtils.setScale( character, 1 );
			
			positionPlayer(character);
			
			var skin:Skin = character.get(Skin);
			
			lookParts = new Vector.<SkinPart>();
			lookParts.push(skin.getSkinPart(SkinUtils.MARKS), skin.getSkinPart(SkinUtils.MOUTH));
			
			var disp:Display = character.get(Display);
			disp.displayObject.mask = content.mirror;
			DisplayUtils.moveToOverUnder(disp.displayObject, content.screenBlock, false);
		}
		
		private function positionPlayer(player:Entity):void
		{
			var spatial:Spatial = player.get(Spatial);
			spatial.x = content.width / 2;
			spatial.y = content.height * 3 / 4;
		}
	}
}