package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Static extends Component
	{
		public var charge:Number;
		public var hasCharge:Boolean;
		public var charged:Boolean;
		public var fullyCharged:Signal;
		public var discharged:Signal;
		public var dischargeRate:Number;
		public var maxCharge:Number;
		public var infiniteCharge:Boolean;
		public var looseChargeOverTime:Boolean;
		public var inContact:Boolean;
		public var transferPriority:Number;//1 disipates more often, 0 recieves more often
		public var contact:Static;
		public var entity:Entity;
		
		public function Static(entity:Entity, transferPriority:Number, dischargeRate:Number = 2, maxCharge:Number = 4, looseChargeOverTime:Boolean = false)
		{
			this.entity = entity;
			this.transferPriority = transferPriority;
			
			inContact = false;
			charge = 0;
			
			fullyCharged = new Signal(Entity,Entity);
			discharged = new Signal(Entity);
			
			this.dischargeRate = dischargeRate;
			this.maxCharge = maxCharge;
			
			infiniteCharge = false;
			if(maxCharge == 0)
				infiniteCharge = true;
			
			hasCharge = infiniteCharge;
			
			this.looseChargeOverTime = looseChargeOverTime;
			
			if(infiniteCharge)
				charge = maxCharge;
		}
		
		public function contactStaticObject(staticObject:Static):void
		{
			contact = staticObject;
			inContact = true;
			staticObject.contact = this;
			staticObject.inContact = true;
		}
		
		public function chargeUp( chargeRate:Number, charger:Entity):Boolean
		{
			if(charged)
				return false;
			
			charge += chargeRate;
			hasCharge = true;
			if(charge > maxCharge)
			{
				charge = maxCharge;
				charged = true;
				fullyCharged.dispatch(entity, charger);
			}
			return true;
		}
		
		public function discharge(time:Number):void
		{
			if(!hasCharge)
				return;
			
			var chargeTransfer:Number = dischargeRate * time;
			
			var transfered:Boolean;
			
			if(contact != null)
			{
				if(transferPriority > contact.transferPriority)
					 transfered = contact.chargeUp(chargeTransfer, entity);
			}
			
			if(infiniteCharge)
				return;
			
			if(transfered || !transfered && looseChargeOverTime)
				charge -= chargeTransfer;
			
			if(charge < 0)
			{
				inContact = false;
				contact = null;
				charge = 0;
				hasCharge = false;
				charged = false;
				discharged.dispatch(entity);
			}
		}
	}
}