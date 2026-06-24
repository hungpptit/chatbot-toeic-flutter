'use strict';
import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Subscription extends Model {
    static associate(models) {
      Subscription.hasMany(models.UserSubscription, { foreignKey: 'subscriptionId' });
    }
  }

  Subscription.init({
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    price: {
      type: DataTypes.DECIMAL(18, 2),
      allowNull: false
    },
    durationDays: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    description: {
      type: DataTypes.STRING(500),
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'Subscription',
    tableName: 'Subscriptions',
    timestamps: true,
  });

  return Subscription;
};
