package game.scenes.examples.characterParts{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.PartLayer;
	import game.creators.ui.ButtonCreator;
	import game.data.character.LookData;
	import game.scene.template.PlatformerGameScene;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	public class CharacterParts extends PlatformerGameScene
	{
		public function CharacterParts()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/characterParts/";
			
			super.init(container);
		}
		
		override public function loaded():void
		{
			setupExampleButtons();

			super.loaded();
		}

		private function setupExampleButtons():void
		{
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			btnClip = MovieClip(super._hitContainer).btn1;
			ButtonCreator.createButtonEntity( btnClip, this, changePart );
			ButtonCreator.addLabel( btnClip, "Swap Shirt", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			btnClip = MovieClip(super._hitContainer).btn2;
			ButtonCreator.createButtonEntity( btnClip, this, changeColor );
			ButtonCreator.addLabel( btnClip, "Change Color", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn3;
			ButtonCreator.createButtonEntity( btnClip, this, applyLook );
			ButtonCreator.addLabel( btnClip, "Apply Look", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn4;
			ButtonCreator.createButtonEntity( btnClip, this, revertLook );
			ButtonCreator.addLabel( btnClip, "Revert Look", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn5;
			ButtonCreator.createButtonEntity( btnClip, this, changingLayers );
			ButtonCreator.addLabel( btnClip, "Layer Change", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn6;
			ButtonCreator.createButtonEntity( btnClip, this, changeLayerBack );
			ButtonCreator.addLabel( btnClip, "Revert Change", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn7;
			ButtonCreator.createButtonEntity( btnClip, this, updateLookByEvent );
			ButtonCreator.addLabel( btnClip, "Look By Event", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn8;
			ButtonCreator.createButtonEntity( btnClip, this, removeEvent );
			ButtonCreator.addLabel( btnClip, "Remove Event", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////// CHARACTER PARTS EXAMPLES //////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * The way that character parts work is pretty complex.
		 * There are a lot of moving parts and a lot of classes involved.
		 * This example is not going to explain how all those classes work,
		 * that is better suited for a visual diagram.
		 * 
		 * Instead these examples we will focus on how to easily manipulate parts using Utilities methods.
		 * We will leave the nuts and bolts of how the sytems work to minimum
		 * 
		 * So let's get started
		 */
		
		private function changePart( button:Entity ):void
		{	
			// get a reference to first npc
			var redHead:Entity = super.getEntityById("redHead");
			
			// get the npc's current shirt part value using a utility method
			var currentShirtValue:String = SkinUtils.getSkinPart(redHead, SkinUtils.SHIRT).value;
			/**
			 * This is helper method is shorthand for this process:
				 * 
				 * var skinValue:String = Skin( character.get( Skin ) ).getSkinPart( skinId );
				 * 
			 * Which is shorthand for this:
				 * 
				 * var skin:Skin = character.get(SKin) as Skin;
				 * var skinId:String = SkinUtils.SHIRT; // this is just a static const equal to "shirt"
				 * var skinPart:SkinPart = skin.getSkinPart( skinId );
				 * var skinValue:String = skinPart.value;
				 * 
			 */
			
			// A variable to hold the random shirt value
			var randomShirtValue:String;
			
			// Just some code to select a random shirt from a list
			var possibleShirts:Vector.<String> = new < String >["1", "2", "3", "4", "5", "6", "7", "9", "10", "11"];
			do
			{
				randomShirtValue = possibleShirts[ Math.floor( Math.random() * possibleShirts.length) ];
			}
			while( randomShirtValue == currentShirtValue )
			
			// Apply the new shirt value to the npc's SkinPart for shirt.
			SkinUtils.setSkinPart( redHead, SkinUtils.SHIRT, randomShirtValue );
			/**
			 * SkinUtils.setSkinPart
			 * This utility function allows you to change a part in a single line.
			 * The longhand for this would be this:
				 * 
				 * var skin:Skin = character.get(Skin) as Skin;
				 * var skinId:String = SkinUtils.SHIRT; // this is just a static const equal to "shirt"
				 * var skinPart:SkinPart = skin.getSkinPart( skinId );
				 * skinPart.setValue( randomShirtValue, false )	;
				 * 
			 * The second Boolean paramater in skinPart.setValue() determines if this change is permanent or not.
			 * For an npc this doesn't matter much, but when used for the player it determines if that change
			 * is one that will be saved or not.  We will investigate this in further examples.
			 */
		}
		
		/**
		 * Example 2 : Changing Attributes
		 * 
		 * Changing attributes of a character, like the skin color, hair color, & eye state
		 * is done the same way as changing a regular part, 
		 * you just change the value of the corresponding SkinPart's value 
		 * and that value gets disseminated to the body parts it applies to.
		 */
		private function changeColor( button:Entity ):void
		{	
			/**
			 * Changing a color group works the same as changing a part.
			 * This is because things like hair color, skin color, & eye state
			 * are actually Entities that have their own SkinPart component.
			 * They are not tied directly to a part like shirt or mouth,
			 * but instead hold an array of parts that they effect.
			 * 
			 * In the case of skinColor it's value is applying to these parts:
				 * 
				 * bodySkin, headSkin, arm1, arm2, hand1, hand2, leg1, leg2, foot1, foot2
				 * 
			 * More information about the skin parts you can found in the skinDefault.xml:
				 * 
				 * bin/data/entity/character/human/skinDefault.xml
				 * 
			 */

			var orangeHead:Entity = super.getEntityById("orangeHead");
			
			var randomSkinColorValue:Number;
			var currentSkinColorValue:Number = SkinUtils.getSkinPart(orangeHead, SkinUtils.SKIN_COLOR).value;
			var possibleColors:Vector.<Number> = new < Number >[0xFF0000,0x00FF00,0x0000FF,0x00FFFF,0xFFFF00];
			do
			{
				randomSkinColorValue = possibleColors[ Math.floor( Math.random() * possibleColors.length) ];
			}
			while( randomSkinColorValue == currentSkinColorValue )
			
			SkinUtils.setSkinPart( orangeHead, SkinUtils.SKIN_COLOR, randomSkinColorValue );
		}
		
		/**
		 * Example 3 : Applying Looks
		 * 
		 * You can still apply entire looks to characters and the format is generally the same.
		 * You make a LookData class, which just holds data about what value applied to what skin part.
		 * That LookData can then be applied to the Skin component, which will update the changes.
		 * You can also retrieve a Look class from the Skin component.
		 */
		private function applyLook( button:Entity ):void
		{
			var greenHead:Entity = super.getEntityById("greenHead");
			
			// create a new LookData class
			var lookData:LookData = new LookData();
			
			// apply values to LookData
			lookData.applyLook( SkinUtils.GENDER_FEMALE, 0xFFC844, NaN, EyeSystem.MEAN, "pgeisha1", "pgeisha1", "pgeisha1", "empty", "pgeisha1", "pgeisha1", "athena", "", "athena" );  
			
			// Can also apply value to specific look aspects.
			lookData.getAspect( SkinUtils.PANTS ).value = "pbiker1";
			
			// Applying a value of "" or null to a aspect of the look, will remove it from the LookData. 
			// Here we remove pgeisha1's mouth from the LookData, for the current mouth will remain.
			lookData.getAspect( SkinUtils.MOUTH ).value = "";

			// Use shorthand method to get Skin and apply a LookData to it.
			SkinUtils.applyLook( greenHead, lookData, false, lookLoaded );
			
			/**
			 * SkinUtils.applyLook is shorthand for:
				 * 
				 * var skin:Skin = orangeHead.get( Skin ) as Skin;
				 * skin.applyLook( lookData );
				 * 
			 * In this case we do not want the look to be made permanent, so we set the isPermanant param to false.
			 * This will allow us to revrt the look to it's previous values.
			 */
			
			// You can also get LookData from a character's Skin, using SkinUtils.getLook.
			var getLook:LookData = SkinUtils.getLook( greenHead );	
			// Since the LookData we just applied was not applied as as permanent, 
			// the LookData returned here will contain the Skin's permanent values
			
			getLook = SkinUtils.getLook( greenHead, false);
			// If we want to get a LookData that reflects the Skin's current values, 
			// we set SkinUtils.getLook's fromPermanent param to false.
		}
		
		private function lookLoaded( enity:Entity ):void
		{
			trace("Wow, the look has finished loading all of it's parts!");
		}
		
		/**
		 * Reverting changes to the skin that have not been made permanent is easy, 
		 * just call revert on Skin and allskin parts will chnage to their 'permanent' values. 
		 * 
		 * @param	button
		 */
		private function revertLook( button:Entity ):void
		{
			var greenHead:Entity = super.getEntityById("greenHead");
			var skin:Skin = greenHead.get(Skin) as Skin;
			
			// Call revertAll, to change all the skin parts to permananet their values.
			skin.revertAll();
			
			// You can also revert skin parts individual.
			skin.getSkinPart( SkinUtils.PANTS ).revertValue();
			
			/**
			 * If you want to remove a part entirely, you can use remove()
			 * in addition you can decide if you want this to be permanent or not:
				 * 
				 * skin.getSkinPart( SkinUtils.HAIR ).remove();
				 * 
			 */
		}
		
		/**
		 * EXAMPLE 4 : Layering Swap
		 * 
		 * Another new feature is being able to swap the layer depth of part son your character
		 */
		private function changingLayers( button:Entity ):void
		{
			var blueHead:Entity = super.getEntityById("blueHead");
		
			// get the PartLayer component from the correct part entity
			var partLayer:PartLayer = CharUtils.getPartLayer( blueHead, CharUtils.HAIR );
			/**
			 * CharUtils.getPartLayer is short hand for this:
				 * 
				 * var rig:Rig = blueHead.get(Rig) as Rig;
				 * var partEntity:Entity = rig.getPart( CharUtils.HAIR_PART );
				 * var partLayer:PartLayer = partEntity.get( PartLayer ) as PartLayer; 
			 */
			
			// Call PartLayer's setInsert method to change the part's layer dpeth
			partLayer.setInsert( CharUtils.HEAD_PART, true );
			/**
			  * use PartLayer's setInsert() to specify another part as your target.
			  * The second parameter determines if you want to move the current part
			  * to a layer above or below the target part's layer.
			  * 
			  * If you know the layer depth you want to move your part to 
			  * you can set the layer depth directly:
				 * 
				 * partLayer.layer = 5;
				 * 
			  * But most of the time you'll probably just want to use setInsert()
			  * since it doesn't necessitate you knowing the layer depth of the parts.
			  */
		}
		
		/**
		 * We use this function to return the part to it's original layer 
		 * @param	button
		 */
		private function changeLayerBack( button:Entity ):void
		{
			var blueHead:Entity = super.getEntityById("blueHead");
			var partLayer:PartLayer = CharUtils.getPartLayer( blueHead, CharUtils.HAIR );
			
			/**
			 * Since the hair is normally behind the head, we keep the head part as our target,
			 * but this time we set the 2nd paramenter, the above Boolean, to false.
			 * This now specifies that we want to move our part to the layer beneath the head.
			 */
			partLayer.setInsert( CharUtils.HEAD_PART, false );
	
		}
		
		/**
		 * We can update character looks by events. 
		 * To do this we need to add another nppc entry in the npc.xml and tie it to an event.
		 * The npc's id must be the same, but we can change the look, we only need to specify the parts that will change.
		 * The look will be applied when the event is fired.
		 * @param	button
		 */
		private function updateLookByEvent( button:Entity ):void
		{
			// we'll just fire the event and let the ChracterUpdateSystem manage the change
			shellApi.triggerEvent( "change_purple_look" );
		}
		
		private function removeEvent( button:Entity ):void
		{
			// we trigger the default event to return the npcs to their defaults
			shellApi.triggerEvent( "default" );
		}
	}
}