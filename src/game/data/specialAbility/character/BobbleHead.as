// Used by:
// Card 2575 using facial ad_swr_helmet
// Card 3071 using ability bobblehead

package game.data.specialAbility.character 
{
	import flash.utils.getDefinitionByName;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.motion.Spring;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.SkinUtils;

	/**
	 * Makes head vibrate (bobble) as avatar walks
	 * 
	 * Optional params:
	 * facial		String		Facial part ID
	 */
	public class BobbleHead extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if( !this.data.isActive )
			{
				startFacial = SkinUtils.getSkinPart(super.entity,SkinUtils.FACIAL);
				
				if( _facial )
				{
					useFacial = true;
					var lookAspect:LookAspectData = new LookAspectData( SkinUtils.FACIAL, _facial); 
					var lookData:LookData = new LookData();
					lookData.applyAspect( lookAspect );
					if(SkinUtils.getLook(super.entity) != null)
						SkinUtils.applyLook( super.entity, lookData, false );
				}
				
				trace("BobbleHead :: activate");
				startScaleX = CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleX;
				startScaleY = CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleY;
				CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleX = CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleY = 1.4;
				var spring:Spring = CharUtils.getJoint( super.entity, CharUtils.HEAD_JOINT).get(Spring);
				startOffsetY = spring.offsetYOffset;
				startDamp = spring.damp;
				startSpring = spring.spring;
				spring.offsetYOffset = -30;
				spring.damp = 0.9;
				spring.spring = .1;
				spring.threshold = 1;
				bActive = true;
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleX = startScaleX;
			CharUtils.getPart( super.entity, CharUtils.HEAD_PART ).get(Spatial).scaleY = startScaleY;
			var spring:Spring = CharUtils.getJoint( super.entity, CharUtils.HEAD_JOINT).get(Spring);
			spring.offsetYOffset = startOffsetY;
			spring.damp = startDamp;
			spring.spring = startSpring;
			
			if( useFacial )
				startFacial.remove(true);
			
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, super.data.id);
			bActive = false;
			super.setActive( false );
		}
		
		public var _facial:String;
		
		private var bActive : Boolean = false;
		private var startScaleX : Number;
		private var startScaleY : Number;
		private var startOffsetY : Number;
		private var startDamp : Number;
		private var startSpring : Number;
		private var startFacial:SkinPart;
		private var useFacial:Boolean = false;
	}
}